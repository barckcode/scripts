import click, subprocess
from subprocess import call

@click.command()
@click.option(
    '--profile',
    prompt='Your AWS profile',
    help='Profile to validate on AWS.'
)
@click.option(
    '--region',
    prompt='Your AWS region',
    help='Region to use on AWS.'
)
@click.option(
    '--autoscaling-name',
    prompt='The name of the autoscaling group',
    help='Name of the autoscaling group where the IP of the instances will be searched.'
)
def list_ip(profile, region, autoscaling_name):
    """
    Script to list the private IP of instances in an autoscaling group
    """
    cmd = ['aws', '--profile', profile, 'autoscaling', 'describe-auto-scaling-groups', '--region=' + region, '--auto-scaling-group-name=' + autoscaling_name, '--query', 'AutoScalingGroups[*].Instances[*].InstanceId', '--output=text']
    proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)

    o, e = proc.communicate()

    print('--> Loading the IPs of the servers...')

    if not e:
        output_file = '/home/ubuntu/list_instances_' + autoscaling_name
        print('--> Saving the IPs in ' + output_file)
        print('Output: ' + o.decode('ascii'))
        print('code: ' + str(proc.returncode))

        for instance in o:
            call(['echo', instance, '>>', output_file], shell=True)

        print('--> Successfully completed!')

    else:
        print('--> Failed to get the IPs of the servers.')
        print('Error: '  + e.decode('ascii'))
        print('code: ' + str(proc.returncode))



if __name__ == '__main__':
    list_ip()
