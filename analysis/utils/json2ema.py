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
import json

LEVEL = [logging.WARNING, logging.INFO, logging.DEBUG]

CHANNELS =  ["T3", "T2", "T1", "ref"] # FIXME: it is so harcoded.....

###############################################################################
# Functions
###############################################################################
def generateEMA(input_filename, output_filename):
    with open(input_filename) as f:
        json_ema = json.load(f)

        nb_frames = int(len(json_ema["channels"][CHANNELS[0]]["position"])/3)
        matrix = np.ndarray((nb_frames, len(CHANNELS)*3),dtype=np.float32)

        for i in range(0, nb_frames):
            for j, c in enumerate(CHANNELS):
                for d in range(0, 3):
                    matrix[i, j*3+d] = json_ema["channels"][c]["position"][i*3+d]

        with open(output_filename, "wb") as f_out:
            matrix.tofile(f_out)

###############################################################################
# Main function
###############################################################################
def main():
    """Main entry function
    """
    global args
    generateEMA(args.input_filename, args.output_filename)

###############################################################################
#  Envelopping
###############################################################################
if __name__ == '__main__':
    try:
        parser = argparse.ArgumentParser(description="")

        # Add options
        parser.add_argument("-v", "--verbosity", action="count", default=0,
                            help="increase output verbosity")

        # Add arguments
        parser.add_argument("input_filename", help="json formatted input")
        parser.add_argument("output_filename", help="output binary file")

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
