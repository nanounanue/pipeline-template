from nose.tools import *

import dummy.pipelines.dummy

def setup():
    print("SETUP")


def teardown():
    print("TEARDOWN")


def test_basic():
    print("Ejecutando test_basic")
