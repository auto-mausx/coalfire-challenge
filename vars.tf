variable "AWS_REGION" {
    default = "us-east-1"
}

variable "availability_zones" {
    type = list(string)
    default = [ "us-east-1a", "us-east-1f" ]
}

variable "public_subnet" {
    type = list(string)
    default = ["10.1.0.0/24", "10.1.1.0/24"]
}

variable "private_subnet" {
    type = list(string)
    default = ["10.1.2.0/24" , "10.1.3.0/24"]
}

variable "ami" {
    type = map(string)

    default = {
        us-east-1 = "ami-011b3ccf1bd6db744"
        us-west-2 = "ami-036affea69a1101c9"
        eu-west-1 = "ami-0e12cbde3e77cbb98"
    }
}

variable "key_path" {

    type = string

    default = "./poc-key.pub"
  
}