FROM amazonlinux:2.0.20210326.0

RUN yum -y install mdadm nvme-cli bash e2fsprogs xfsprogs
COPY eks-nvme-ssd-provisioner.sh /usr/local/bin/

ENTRYPOINT ["eks-nvme-ssd-provisioner.sh"]
