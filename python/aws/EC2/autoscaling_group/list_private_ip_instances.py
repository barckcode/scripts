import click

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
    print(profile)
    print(region)
    print(autoscaling_name)

if __name__ == '__main__':
    list_ip()
