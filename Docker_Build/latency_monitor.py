import sys
import os
import datetime
import configparser
from threading import *
from time import *
from pythonping import ping
# pip3 install influxdb-client
from influxdb_client import InfluxDBClient, Point, WriteOptions, WritePrecision

class MyInfluxDB():
    """
    Class for InfluxDB connections.
    
        Reads config from *config.ini*:
            [influx]
            infx_url = Influx2 URL like: *http://10.0.0.1:8086* (must)
            infx_token = Influx2 Token for corresponding bucket (must)
            infx_bucket = Influx2 Bucket (must)
            infx_org = Influx2 Organization (must)

    Attributes
    ----------
        n.a.

    Methods
    -------
        write(host(string), host_location(string), ping_response(string))
            writes received data to Influxdb:
                host: string which includes IP or FQDN
                host_location: string which includes location of the host
                ping_response: float which includes the ping reply in ms
    """

    def __init__(self):

        ## IF ENVIRONMENT VARIABLES ARE PASSED IGNORE CONFIG FILE
        if 'INFLUX_URL' in os.environ:

            INFX_URL = os.environ['INFLUX_URL']
            INFX_TOKEN = os.environ['INFLUX_TOKEN']
            INFX_BUCKET = os.environ['INFLUX_BUCKET']
            INFX_ORG = os.environ['INFLUX_ORG']
            INFX_BATCH = os.getenv('INFLUX_BATCH', 60)   # if not set use default
            INFX_FINT = os.getenv('INFLUX_FINT', 30_000) # if not set use default
            INFX_JINT = os.getenv('INFLUX_JINT', 5_000)  # if not set use default
            INFX_RINT = os.getenv('INFLUX_RINT', 5_000)  # if not set use default
            
        else:

            config_file = os.path.join(os.path.dirname(__file__), 'config.ini')
            config = configparser.ConfigParser()
            config.read(config_file)

            INFX_URL = config['influx']['infx_url']
            INFX_TOKEN = config['influx']['infx_token']
            INFX_BUCKET = config['influx']['infx_bucket']
            INFX_ORG = config['influx']['infx_org']
            INFX_BATCH = config.get('influx', 'infx_batch_size', fallback=60)        # if not set use default
            INFX_FINT = config.get('influx', 'infx_flush_interval', fallback=30_000) # if not set use default 
            INFX_JINT = config.get('influx', 'infx_jitter_interval', fallback=5_000) # if not set use default
            INFX_RINT = config.get('influx', 'infx_retry_interval', fallback=5_000)  # if not set use default

        # This one is needed in our methods    
        self.INFX_BUCKET = INFX_BUCKET

        # create influxdb client
        self.client = InfluxDBClient(url=INFX_URL,
                                     token=INFX_TOKEN,
                                     org=INFX_ORG,
                                     verify_ssl=False)

        # create influxdb write api
        self.write_api = self.client.write_api(write_options=WriteOptions(batch_size=INFX_BATCH,
                                                                          flush_interval=INFX_FINT,
                                                                          jitter_interval=INFX_JINT,
                                                                          retry_interval=INFX_RINT))

    def __del__(self):
        self.client.close()

    def write(self, host, host_location, ping_response):
        self.host = host
        self.host_location = host_location
        self.ping_response = float(ping_response)
        self.influx_timestamp = int(time_ns())
        self.data_point = Point("latency_monitor").tag("location", self.host_location).tag("host", self.host).field("latency", self.ping_response).time(self.influx_timestamp)
        self.write_api.write(bucket=self.INFX_BUCKET,
                             record=self.data_point, 
                             write_precision='s')


class ThreadPing(Thread):
    """
    Class of type thread which *pings* given hosts and passes data to InfluxDB2.
        - one thread for each ping
        - passes ping results to given InfluxDB2 
    
    Arguments
    ----------
        db: InfluxDB Object
        host: string which includes IP or FQDN
        host_timeout: float which defines how long we wait for a reply
        host_timer: integer which defines how often pings are send in seconds (min. 1)
        host_location: string which includes location of the host
    """

    def __init__(self, db, host, host_timeout, host_timer, host_location):
        Thread.__init__(self)
        self.MyDB = db
        self.host = host
        self.host_timeout = host_timeout
        self.host_timer = host_timer
        self.host_location = host_location

    def run(self):
        self.starttime = time()
        while True:
            self.ping_response_list = ping(self.host, timeout=self.host_timeout, count=1)
            self.ping_response = "{:.2f}".format(self.ping_response_list.rtt_avg_ms)
            self.MyDB.write(self.host, self.host_location, self.ping_response)
            sleep(self.host_timer - ((time() - self.starttime) % 1))
    

def main():
    
    MyDB = MyInfluxDB()
    
    # Place to store running threads...
    my_threads = []

    ## IF ENVIRONMENT VARIABLES ARE PASSED IGNORE CONFIG FILE
    if 'TARGET_HOST' in os.environ:
        host = os.environ['TARGET_HOST']
        host_timeout = float(os.getenv('TARGET_TIMEOUT', 1))
        host_timer = int(os.getenv('TARGET_TIMER', 5))
        host_location = os.getenv('TARGET_LOCATION', 'unknown')
        
        # Create Thread
        print("Creating thread for: %s, with interval: %s and location: %s" % (host, host_timeout, host_timer, host_location))
        thread = ThreadPing(MyDB, host, host_timeout, host_timer, host_location)
        my_threads.append(thread)
        thread.start()

    else:

        ## Read Config file
        config_file = os.path.join(os.path.dirname(__file__), 'config.ini')
        config = configparser.ConfigParser()
        config.read(config_file)
        host_items = config.items("hosts")

        # Create thread for each configured host
        for key, host in host_items:

            # Check if hosts timeout is set otherwise use "1" (means 1 seconds)
            host_timeout = float(config.get('hosts_timeout', key, fallback=1))

            # Check if hosts timer is set otherwise use "5" (means 5 seconds)
            host_timer = int(config.get('hosts_timer', key, fallback=5))

            # Check if hosts location is set otherwise use "unknown"
            host_location = config.get('hosts_location', key, fallback="unknown")

            # Create Thread
            print("Creating thread for: %s, with timeout: %s, with interval: %s and location: %s" % (host, host_timeout, host_timer, host_location))
            thread = ThreadPing(MyDB, host, host_timeout, host_timer, host_location)
            my_threads.append(thread)
            thread.start()

    # Join one child thread otherwise main thread will stop (endless loop is also an option)
    for thread in my_threads:
        thread.join()

    
if __name__ == '__main__':
    main()


