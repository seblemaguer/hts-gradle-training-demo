#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
AUTHOR

    Sébastien Le Maguer <slemaguer@coli.uni-saarland.de>

DESCRIPTION

LICENSE
    This script is in the public domain, free from copyrights or restrictions.
    Created: 12 October 2016
"""

import sys
import os
import traceback
import argparse
import time
import logging
import numpy as np
import subprocess

LEVEL = [logging.WARNING, logging.INFO, logging.DEBUG]

# channels =  ["T3", "T2", "T1", "ref", "jaw", "upperlip", "lowerlip"]

###############################################################################
# Functions
###############################################################################
def generateJSON(input_filename, output_filename,channels):
    input_data = np.fromfile(input_filename, dtype=np.float32)
    nb_frames = int(input_data.size / (len(channels)*3))

    # print("nb_frames = %d, size_frame = %d, total = %d, orig_size = %d" % (nb_frames, len(channels)*3, len(channels)*3*nb_frames, input_data.size))
    input_data = np.reshape(input_data, (nb_frames, len(channels)*3))

    with open(output_filename, "w") as output_file:
        output_file.write("{\n")
        output_file.write("\t\"channels\": {\n")
        for idx_c in range(0, len(channels)):
            c = idx_c*3
            output_file.write("\t\t\"%s\": {\n" % channels[idx_c])
            output_file.write("\t\t\t\"position\": [\n")

            # Frame values
            for f in range(0, nb_frames-1):
                output_file.write("\t\t\t\t%f, " % input_data[f, c])
                output_file.write("\t\t\t\t%f, " % input_data[f, c+1])
                output_file.write("\t\t\t\t%f,\n" % input_data[f, c+2])
                # output_file.write("\t\t\t\t%f," % 0)

            # Last frame
            output_file.write("\t\t\t\t%f, " % input_data[nb_frames-1, c])
            output_file.write("\t\t\t\t%f, " % input_data[nb_frames-1, c+1])
            output_file.write("\t\t\t\t%f\n" % input_data[nb_frames-1, c+2])
            # output_file.write("\t\t\t\t%f" % 0)

            # Closing
            output_file.write("\t\t\t]\n")
            output_file.write("\t\t},\n")

        output_file.write("\t\t\"ignore\": {\n")
        output_file.write("\t\t}\n")
        output_file.write("\t},\n")

        output_file.write("\t\"timestamps\": [\n")
        for f in range(0, nb_frames-1):
            output_file.write("\t\t%f,\n" % (f*0.005))

        output_file.write("\t\t%f\n" % ((nb_frames-1)*0.005))
        output_file.write("\t]\n")

        output_file.write("}\n")


###############################################################################
# Main function
###############################################################################
def main():
    """Main entry function
    """
    global args
    channels = args.channels.split(",")
    generateJSON(args.input_filename, args.output_filename, channels)

###############################################################################
#  Envelopping
###############################################################################
if __name__ == '__main__':
    try:
        parser = argparse.ArgumentParser(description="")

        # Add options
        parser.add_argument("-v", "--verbosity", action="count", default=0,
                            help="increase output verbosity")
        parser.add_argument("-c", "--channels", help="channels separated by comma (ex. T3,T2,...)")

        # Add arguments
        parser.add_argument("input_filename", help="binary formatted input")
        parser.add_argument("output_filename", help="output directory")

        # Parsing arguments
        args = parser.parse_args()

        # Verbose level => logging level
        log_level = args.verbosity
        if (args.verbosity > len(LEVEL)):
            logging.warning("verbosity level is too high, I'm gonna assume you're taking the highes ")

            log_level = len(LEVEL) - 1
            logging.basicConfig(level=LEVEL[log_level])

            # Debug time
            start_time = time.time()
            logging.info("start time = " + time.asctime())

        # Running main function <=> run application
        main()

        if (args.verbosity > len(LEVEL)):
            # Debug time
            logging.info("end time = " + time.asctime())
            logging.info('TOTAL TIME IN MINUTES: %02.2f' %
                         ((time.time() - start_time) / 60.0))

        # Exit program
        sys.exit(0)
    except KeyboardInterrupt as e:  # Ctrl-C
        raise e
    except SystemExit as e:  # sys.exit()
        pass
    except Exception as e:
        logging.error('ERROR, UNEXPECTED EXCEPTION')
        logging.error(str(e))
        traceback.print_exc(file=sys.stderr)
        sys.exit(-1)

# ema2alex.py ends here
