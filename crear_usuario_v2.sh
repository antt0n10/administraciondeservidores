#!/bin/bash

MIN_LENGTH=8

validar_password() {
    local pass="$1"

    if [[ ${#pass} -lt $MIN_LENGTH ]]; then
        echo "La contraseña debe tener al menos $MIN_LENGTH caracteres"
        return 1
    fi

    if [[ ! "$pass" =~ [A-Z] ]]; then
        echo "Debe contener al menos una letra mayúscula"
        return 1
    fi

    if [[ ! "$pass" =~ [0-9] ]]; then
        echo "Debe contener al menos un número"
        return 1
    fi

    if [[ ! "$pass" =~ [^a-zA-Z0-9] ]]; then
        echo "Debe contener al menos un símbolo"
        return 1
    fi

    return 0
}

read -p "Nombre de usuario: " usuario

if id "$usuario" &>/dev/null; then
    echo "El usuario ya existe"
    exit 1
fi

while true; do
    read -s -p "Contraseña: " password
    echo
    read -s -p "Confirmar contraseña: " password2
    echo

    if [[ "$password" != "$password2" ]]; then
        echo "Las contraseñas no coinciden"
        continue
    fi

    validar_password "$password"
    if [[ $? -eq 0 ]]; then
        break
    fi
done

sudo useradd -m "$usuario"
echo "$usuario:$password" | sudo chpasswd

# CUOTAS
read -p "¿Deseas asignar cuota de disco? (s/n): " cuota

if [[ "$cuota" == "s" || "$cuota" == "S" ]]; then
    read -p "Límite soft (KB): " soft
    read -p "Límite hard (KB): " hard

    sudo setquota -u "$usuario" $soft $hard 0 0 -a

    read -p "¿Cambiar periodo de gracia? (s/n): " gracia

    if [[ "$gracia" == "s" || "$gracia" == "S" ]]; then
        read -p "Periodo (ej: 7days, 12hours): " periodo
        sudo setquota -t $periodo $periodo -a
    fi
fi

# SUDO
read -p "¿El usuario tendrá permisos sudo? (s/n): " usesudo

if [[ "$usesudo" == "s" || "$usesudo" == "S" ]]; then
    read -p "¿Permitir todos los comandos? (s/n): " allcmd

    if [[ "$allcmd" == "s" || "$allcmd" == "S" ]]; then
        echo "$usuario ALL=(ALL) ALL" | sudo tee /etc/sudoers.d/$usuario > /dev/null
    else
        read -p "Escribe los comandos permitidos (separados por coma): " comandos
        echo "$usuario ALL=(ALL) $comandos" | sudo tee /etc/sudoers.d/$usuario > /dev/null
    fi

    sudo chmod 440 /etc/sudoers.d/$usuario
fi

echo "Usuario creado y configurado correctamente"
