# Terraform plan for deployment of OpenStack Sunbeam

## Overview

This project provides a number of Terraform modules and a top level Terraform
plan for deployment and operation of OpenStack Sunbeam Charmed K8S Operators.

This subset of Charmed Operators form the control plan for a Sunbeam deployed
OpenStack Cloud and by default are tested with MicroK8S.

The plans and modules make use of the Juju Terraform Provider to interact
with a previously bootstrapped Juju controller; the plan takes care of creation
of the Juju model and deployment of the Charmed Operators including creation
of all required relations.

## Variables

The Terraform plan provides a number of variables to help with configuration of
deployment options - see 'variables.tf' for full details.