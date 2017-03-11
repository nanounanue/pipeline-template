#!/usr/bin/env python

import click
import socket

import sys
import luigi

import dummy.pipelines.dummy

def check_server(host, port):
    """
    Verifica si el servidor de luigi está ejecutándose
    """
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    try:
        server.connect((host, port))
        return True
    except socket.error as e:
        return False
    finally:
        server.close()

@click.command()
@click.option('--server', help='URL donde se encuentra el luigi-master', default='localhost')
@click.option('--port', help='Puerto donde está escuchando el luigi-master', default=8082)
@click.option('--luigi_cfg', help='Path al archivo de configuración de Luigi', type=click.Path())
#@click.option('--level', help='', default=2, type=click.INT)
#@click.option('--sleep', help='', default=2, type=click.INT)
def main(server, port, luigi_cfg):
    """
    Ejecuta el pipeline 
    """

    luigi_args = ['DummyPipeline'
                  # '--level', str(level), 
                  # '--sleep', str(sleep),
                 ]

    ## Ejecuta luigi con el local scheduler si no hay servidor
    if not check_server(server, port):
        luigi_args.append('--local-scheduler')

    luigi.run(luigi_args)

if __name__ == '__main__':
    main()



