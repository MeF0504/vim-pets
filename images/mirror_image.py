#! /usr/bin/env python3

import argparse
from pathlib import Path

from PIL import Image, ImageOps


def main(args):
    with Image.open(args.file) as img:
        im2 = ImageOps.mirror(img)
    outfile = Path(args.file).with_stem('output')
    im2.save(outfile)
    print(f'output the image at {outfile}.')


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('file', help='image file')
    args = parser.parse_args()
    main(args)
