[control_plane]
%{ for name, n in inventory_nodes ~}
%{ if n.group == "control_plane" ~}
${name} ansible_host=${n.public_ip} private_ip=${n.private_ip}
%{ endif ~}
%{ endfor ~}

[workers]
%{ for name, n in inventory_nodes ~}
%{ if n.group == "workers" ~}
${name} ansible_host=${n.public_ip} private_ip=${n.private_ip}
%{ endif ~}
%{ endfor ~}

[all:vars]
ansible_user=${ansible_user}
ansible_ssh_private_key_file=${ssh_key_path}
ansible_python_interpreter=/usr/bin/python3
ansible_ssh_common_args=-o StrictHostKeyChecking=accept-new
