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

# Preguntar si se desea configurar cuota
read -p "¿Deseas asignar cuota de disco? (s/n): " cuota

if [[ "$cuota" == "s" || "$cuota" == "S" ]]; then
    read -p "Límite soft (en bloques KB): " soft
    read -p "Límite hard (en bloques KB): " hard

    # Asignar cuota (requiere que el sistema tenga cuotas activadas)
    sudo setquota -u "$usuario" $soft $hard 0 0 -a

    read -p "¿Deseas cambiar el periodo de gracia? (s/n): " gracia

    if [[ "$gracia" == "s" || "$gracia" == "S" ]]; then
        read -p "Periodo de gracia (ej: 7days, 12hours): " periodo
        sudo setquota -t $periodo $periodo -a
    fi
fi

echo "Usuario creado correctamente"
