//iam role for eks cluster
resource "aws_iam_role" "eks_cluster" {
	name = "eks_cluster_role"

	assume_role_policy = jsonencode({
		"Version": "2012-10-17",
  		"Statement": [
    			{
			      "Effect": "Allow",
			      "Principal": {
			        "Service": "eks.amazonaws.com"
      			       },
			      "Action": "sts:AssumeRole"
		        }
			  ]
		})
}


resource "aws_iam_policy_attachment" "eks_cluster_policy" {
	name = "eks_cluster_policy"
	roles = [aws_iam_role.eks_cluster.name]
	policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"

}

data "aws_vpc" "default" {
	default = true
}


data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}


resource "aws_eks_cluster" "eks-cloud" {
	name = "my-eks-cluster"
	role_arn = aws_iam_role.eks_cluster.arn
	 vpc_config {
    		subnet_ids = data.aws_subnets.public.ids
	  }
	

}

//iam role for node group
resource "aws_iam_role" "node_role" {
	name = "eks_node_role"
	assume_role_policy = jsonencode(
	{
 	 "Version": "2012-10-17",
	  "Statement": [
	    {
	      "Effect": "Allow",
	      "Principal": {
	        "Service": "ec2.amazonaws.com"
	      },
	      "Action": "sts:AssumeRole"
	    }
	  ]
	}
		)
}


resource "aws_iam_role_policy_attachment" "node_policy_workernode" {
	policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
	role = aws_iam_role.node_role.name
	
}

resource "aws_iam_role_policy_attachment" "node_policy_cni" {
	policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
	role = aws_iam_role.node_role.name
}

resource "aws_iam_role_policy_attachment" "node_policy_ecr" {
	policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
	role = aws_iam_role.node_role.name
}

resource "aws_eks_node_group" "node_group" {
	cluster_name = aws_eks_cluster.eks-cloud.name
	node_group_name = "managed_node"
	node_role_arn = aws_iam_role.node_role.arn
	subnet_ids = data.aws_subnets.public.ids
	scaling_config {
		desired_size = 1
		max_size = 2
		min_size = 1
	}
	instance_types = ["t3.micro"]
	
	depends_on = [
		aws_iam_role_policy_attachment.node_policy_workernode,
		aws_iam_role_policy_attachment.node_policy_cni,
		aws_iam_role_policy_attachment.node_policy_ecr,
		aws_eks_cluster.eks-cloud
	]

}
