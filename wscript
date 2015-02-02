#!/usr/bin/env python

import glob

VERSION=(0,1,0)
APPNAME='valum'

top='.'
out='build'

def options(opt):
    opt.load('compiler_c')

def configure(conf):
    conf.load('compiler_c vala')

    # conf.env.append_unique('VALAFLAGS', ['--enable-experimental-non-null'])

    conf.check_cfg(package='glib-2.0', atleast_version='2.32', uselib_store='GLIB', args='--cflags --libs')
    conf.check_cfg(package='ctpl', atleast_version='0.3.3', uselib_store='CTPL', args='--cflags --libs')
    conf.check_cfg(package='gee-0.8', atleast_version='0.6.4', uselib_store='GEE', args='--cflags --libs')
    conf.check_cfg(package='libsoup-2.4', atleast_version='2.38', uselib_store='SOUP', args='--cflags --libs')
    conf.check_cfg(package='uuid', atleast_version='2.20', uselib_store='UUID', args='--cflags --libs')

    conf.check(lib='fcgi', uselib_store='FCGI', args='--cflags --libs')

    # configure examples
    conf.recurse(glob.glob('examples/*'))

def build(bld):
    # build a static library
    bld.stlib(
        packages    = ['glib-2.0', 'libsoup-2.4', 'gee-0.8', 'ctpl', 'fcgi', 'uuid'],
        target      = 'valum',
        gir         = 'Valum-{}.{}'.format(*VERSION),
        source      = bld.path.ant_glob('src/**/*.vala'),
        uselib      = ['GLIB', 'CTPL', 'GEE', 'SOUP', 'FCGI', 'UUID'],
        vapi_dirs   = ['vapi'])

    # build examples recursively
    bld.recurse(glob.glob('examples/*'))

    # build tests
    bld.recurse('tests')
