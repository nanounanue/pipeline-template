# coding: utf-8
"""
Dummy Pipeline 

.. module:: dummy

   :synopsis: Dummy pipeline

.. moduleauthor:: Adolfo De Unánue <nanounanue@gmail.com>
"""

import os

import subprocess

import pandas as pd

import csv

import datetime

import luigi
import luigi.s3

import sqlalchemy

## Variables de ambiente
from dotenv import load_dotenv, find_dotenv
load_dotenv(find_dotenv())


## Logging
import dummy.config_ini

import logging

logger = logging.getLogger("dpa-template.dummy")


import dummy.pipelines.utils
import dummy.pipelines.common



class DummyPipeline(luigi.WrapperTask):
    """
    Task principal para el pipeline 
    """

    def requires(self):
        yield PySparkTask()

class RTask(luigi.Task):

    root_path = luigi.Parameter()

    def requires(self):
        return RawData()

    def run(self):
        cmd = '''
              docker run --rm --network dummy_net -v dummy_store:/dummy/data  dummy/test-r 
        '''

        logger.debug(cmd)

        out = subprocess.check_output(cmd, shell=True)

        logger.debug(out)

    def output(self):
        return luigi.LocalTarget(os.path.join(os.getcwd(), "data", "hola_mundo_desde_R.psv"))


class PythonTask(luigi.Task):

    def requires(self):
        return RTask()

    def run(self):
        cmd = '''
              docker run --rm --network dummy_net  -v dummy_store:/dummy/data  dummy/test-python --inputfile {} --outputfile {}
        '''.format(os.path.join("/dummy/data", os.path.basename(self.input().path)),
                   os.path.join("/dummy/data", os.path.basename(self.output().path)))

        logger.debug(cmd)

        out = subprocess.call(cmd, shell=True)

        logger.debug(out)

    def output(self):
        return luigi.LocalTarget(os.path.join(os.getcwd(), "data", "hola_mundo_desde_python.json"))


class PySparkTask(luigi.Task):
    def requires(self):
        return PythonTask()

    def run(self):
        cmd = '''
              docker run --rm --network dummy_net -v dummy_store:/dummy/data dummy/test-pyspark --master {} --input {} --output {}
        '''.format("spark://master:7077",
                   os.path.join("/dummy/data", os.path.basename(self.input().path)),
                   os.path.join("/dummy/data", os.path.basename(self.output().path)))

        logger.debug(cmd)

        out = subprocess.call(cmd, shell=True)

        logger.debug(out)

    def output(self):
        return luigi.LocalTarget(os.path.join(os.getcwd(), "data", "hola_mundo_desde_pyspark"))

class SqoopTask(luigi.Task):
    def requires(self):
        return HadoopTask()

    def run(self):
        cmd = '''
                docker run --rm --network dummy_net -v dummy_store:/dummy/data dummy/test-pyspark --master {} --input {} --output {}
        '''

        logger.debug(cmd)

        out = subprocess.call(cmd, shell=True)

        logger.debug(out)

    def output(self):
        return luigi.LocalTarget("hola_mundo_desde_sqoop.txt")

class HadoopTask(luigi.Task):
    def requires(self):
        return PySparkTask()

    def run(self):
        cmd = '''
                docker run --rm --network dummy_net -v dummy_store:/dummy/data dummy/test-pyspark --master {} --input {} --output {}
        '''

        logger.debug(cmd)

        out = subprocess.call(cmd, shell=True)

        logger.debug(out)


    def output(self):
        return luigi.LocalTarget("hola_mundo_desde_hadoop.txt")

class RawData(luigi.ExternalTask):
    def output(self):
        return luigi.LocalTarget("./data/raw_data.txt")


