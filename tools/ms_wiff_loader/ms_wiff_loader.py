#!/usr/bin/env python
import optparse
import os
import sys
import tempfile
import shutil
import subprocess
import re
import logging
import urllib2
from urlparse import urlparse


assert sys.version_info[:2] >= (2, 6)

log = logging.getLogger(__name__)

CHUNK_SIZE = 2**20 #1mb

def stop_err(msg):
    sys.stderr.write("%s\n" % msg)
    sys.exit()

def download_from_url( url, output_dir, basename=None, ext=None ):
    o = urlparse(url)
    src_parts = os.path.basename(o.path).split('.',1)
    file_name = "%s.%s" % ( basename if basename else src_parts[0], ext if ext else src_parts[1] ) 
    file_path = os.path.join(output_dir,file_name)
    reader = urllib2.urlopen( url )
    writer = open(file_path,'wb')
    while True:
        data = reader.read( CHUNK_SIZE )
        if data:
            writer.write( data )
        else:
            break
    writer.close()
    reader.close()
    return file_path

def __main__():
    parser = optparse.OptionParser()
    parser.add_option( '-a', '--archive', dest='archive', default=None, help='URL to archive containing: <name>.wiff file <name>.wiff.scan <name>.wiff.mtd files' )
    parser.add_option( '-w', '--wiff', dest='wiff', default=None, help='URL to <name>.wiff file' )
    parser.add_option( '-s', '--scan', dest='scan', default=None, help='URL to <name>.wiff.scan file' )
    parser.add_option( '-m', '--mtd', dest='mtd', default=None, help='URL to <name>.wiff.mtd file' )
    parser.add_option( '-n', '--name', dest='name', default=None, help='base name for files' )
    parser.add_option( '-o', '--output_dir', dest='output_dir', default=None, help='dir to copy files into' )
    parser.add_option( '-f', '--output_file', dest='output_file', default=None, help='Galaxy dataset file' )
    (options, args) = parser.parse_args()
  
    if not (options.archive or options.wiff):
        stop_err("No wiff input file specified")
    output_dir = os.getcwd()
    if options.output_dir:
        output_dir = options.output_dir
        if not os.path.exists( output_dir ):
            os.makedirs(output_dir)
    basename = options.name
    rval = ['<html><head><title>Wiff Composite Dataset %s</title></head><body><p/>' % (basename if basename else '')]
    rval.append('This composite dataset is composed of the following files:<p/><ul>')
    if options.wiff:
        file_path = download_from_url (options.wiff, output_dir, basename=basename, ext='wiff')
        rel_path = os.path.basename(file_path)
        os.symlink( rel_path, os.path.join(output_dir,'wiff'))
        rval.append( '<li><a href="%s" type="application/octet-stream">%s</a></li>' % ( rel_path, rel_path ) )
        print >> sys.stdout, "wiff: %s" % options.wiff
    if options.scan:
        file_path = download_from_url (options.scan, output_dir, basename=basename, ext='wiff.scan')
        rel_path = os.path.basename(file_path)
        os.symlink( rel_path, os.path.join(output_dir,'wiff_scan'))
        rval.append( '<li><a href="%s" type="application/octet-stream">%s</a></li>' % ( rel_path, rel_path ) )
        print >> sys.stdout, "scan: %s" % options.scan
    if options.mtd:
        file_path = download_from_url (options.mtd, output_dir, basename=basename, ext='wiff.mtd')
        rel_path = os.path.basename(file_path)
        os.symlink( rel_path, os.path.join(output_dir,'wiff_mtd'))
        rval.append( '<li><a href="%s" type="application/octet-stream">%s</a></li>' % ( rel_path, rel_path ) )
        print >> sys.stdout, "mtd:  %s" % options.mtd
    if options.output_file:
        rval.append( '</ul></div></body></html>' )
        f = open(options.output_file,'a')
        f.write("\n".join( rval ))
        f.close()

if __name__ == '__main__':
    __main__()
