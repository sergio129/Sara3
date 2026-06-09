import * as path from 'path';
import { Stack, StackProps, CfnOutput, RemovalPolicy } from 'aws-cdk-lib';
import { Construct } from 'constructs';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as s3 from 'aws-cdk-lib/aws-s3';
import * as ecrAssets from 'aws-cdk-lib/aws-ecr-assets';

export class Sara3LoadTestStack extends Stack {
  constructor(scope: Construct, id: string, props?: StackProps) {
    super(scope, id, props);

    // VPC default + primera subred pública
    const vpc = ec2.Vpc.fromLookup(this, 'DefaultVpc', { isDefault: true });
    const subnet = vpc.publicSubnets[0];

    // Security group existente (provisto): las instancias lo reutilizan.
    const sg = ec2.SecurityGroup.fromSecurityGroupId(this, 'LoadTestSg', 'sg-0658467e965f57371');

    // Imagen Docker -> ECR (assets de CDK). Contexto = raiz del repo.
    const image = new ecrAssets.DockerImageAsset(this, 'Sara3Image', {
      directory: path.join(__dirname, '..', '..'),
    });

    // Bucket de resultados (efimero: se borra con cdk destroy)
    const bucket = new s3.Bucket(this, 'ResultsBucket', {
      removalPolicy: RemovalPolicy.DESTROY,
      autoDeleteObjects: true,
    });

    // Rol + instance profile para las EC2
    const role = new iam.Role(this, 'InstanceRole', {
      assumedBy: new iam.ServicePrincipal('ec2.amazonaws.com'),
      managedPolicies: [
        iam.ManagedPolicy.fromAwsManagedPolicyName('AmazonEC2ContainerRegistryReadOnly'),
      ],
    });
    image.repository.grantPull(role);
    bucket.grantWrite(role);
    const profile = new iam.InstanceProfile(this, 'InstanceProfile', { role });

    // AMI Amazon Linux 2023 (x86_64)
    const amiId = ec2.MachineImage.latestAmazonLinux2023().getImage(this).imageId;

    // Outputs (ids alfanumericos para keys limpias en --outputs-file)
    new CfnOutput(this, 'AwsRegion', { value: this.region });
    new CfnOutput(this, 'EcrImage', { value: image.imageUri });
    new CfnOutput(this, 'S3Bucket', { value: bucket.bucketName });
    new CfnOutput(this, 'SubnetId', { value: subnet.subnetId });
    new CfnOutput(this, 'SecurityGroupId', { value: sg.securityGroupId });
    new CfnOutput(this, 'IamInstanceProfile', { value: profile.instanceProfileName });
    new CfnOutput(this, 'AmiId', { value: amiId });
  }
}
