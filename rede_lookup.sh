#!/usr/bin/env bash
# Template orgulhosamente criado por (Shell-Base)

#-----------HEADER-------------------------------------------------------------|
# AUTOR             : Vovolinux <suporte@vovolinux.com.br>
# HOMEPAGE          : https://vovolinux.com.br 
# DATA-DE-CRIAÇÃO   : 21/10/2019 às 11:13 
# PROGRAMA          : rede_lookup.sh
# VERSÃO            : 1.0.0
# LICENÇA           : MIT
# PEQUENA-DESCRIÇÃO : Lista os dispositivos conectados à rede atual.
#
# CHANGELOG :
#
#------------------------------------------------------------------------------|

#--------------------------------- VARIÁVEIS ---------------------------------->

# CORES:
    end=$(tput sgr0)
    bold=$(tput bold)
    fg_red=$(tput setaf 1)
    fg_green=$(tput setaf 2)
    fg_cyan=$(tput setaf 6)

# STRINGS:
    linha_tracos="----------------------------------"
#------------------------------- FIM-VARIÁVEIS --------------------------------<



#----------------------------------- FUNÇÕES ---------------------------------->
#
# Funções vão aqui!
#
#--------------------------------- FIM-FUNÇÕES --------------------------------<



#---------------------------------- TESTES ------------------------------------>

[ "$UID" -ne "0" ] && {  # é root?
    printf '%b' "${bold}${fg_red}Execute como r00t.${end}\n"
    exit 1
}

# Dependencias existem?
    # Ubuntu: instalar net-tools para netstat
    # Ubuntu: instalar samba-common para nmblookup
    deps=( "nmap" "netstat" "nmblookup")
    for dep in "${deps[@]}"; do
        if ! type -p "$dep" 1>/dev/null 2>&1; then
            printf '%b' "${bold}${fg_red}${dep}${end}${fg_red} não está instalado.${end}\n"
            exit 1
        fi
    done

#--------------------------------- FIM-TESTES ---------------------------------<

# Programa começa aqui :)

# Qual distribuição?
    distro=$(grep 'PRETTY_NAME' "/etc/os-release" | cut -d "\"" -f2)
    printf '%b' "${fg_cyan}> Distribuição: ${distro}${end}\n"

# VERIFCANDO CONEXÕES ATIVAS.
    printf '%b' "${fg_cyan}> Pesquisando conexões...${end}\n"

    if [ "${distro}" = "Ubuntu 19.04" ]; then
        qtdConexoes=$(ip a | grep inet | grep brd -oc)

        if [ "$qtdConexoes" = "0" ]; then
            printf '%b' "${bold}${fg_red}>> ****** Nenhuma conexão ativa. ******${end} \n"
            exit 1       
        else
            if [ "$qtdConexoes" = "1" ]; then
                printf '%b' "${fg_green}>> Uma conexão ativa.${end}\n"
            else
                printf '%b' "${fg_green}>> ${qtdConexoes} conexões ativas.${end}\n"        
            fi
        fi
    
        # Interfaces
            printf '%b' "\n${fg_cyan}> Pesquisando interfaces de rede...${end}\n"
            printf '%b' "${fg_green}>> Obtendo Nomes da(s) interface(s) de rede...${end}\n"
            interfaces=( $(ip a | grep inet | grep brd | sed s'/    / /'g | cut -d " " -f10) )

            printf '%b' "${fg_green}>> Obtendo IP(s) da(s) interface(s) de rede...${end}\n"
            inets=( $(ip a | grep inet | grep brd | sed s'/    / /'g | cut -d " " -f3 | cut -d "/" -f1) )
    fi

# Selecao das interfaces
    selecionada=0     
    n=0
    if [ $qtdConexoes -ne 1 ]; then
        printf '%b' "\n  Interfaces de rede conectadas:\n"
        printf '%b' "  ${linha_tracos}\n"
        for inet in "${inets[@]}"
        do
            let n++
            opcoes=( ${opcoes[@]} "$n" )
            printf '%b' "    $n-${interfaces[$n-1]}\t IP: ${inet}\n"
        done    
        printf '%b' "  ${linha_tracos}\n"
        
        invalida=1
        texto="  Selecione uma interface de rede: "
        while [ $invalida -eq 1 ]; do
            printf '%b' "${texto}"
            read selecionada
            for opc in ${opcoes[@]}
            do
                if [ "$selecionada" = "$opc" ]; then
                    invalida=0
                else
                    texto="  ${bold}${fg_red}Opa! Opção inválida!\n${end}\nDigite o NÚMERO da interface de rede: "
                fi
            done
        done        

        let selecionada--
    fi

    interface=${interfaces[$selecionada]}
    inet=${inets[$selecionada]}

    # Gateway Padrão
        lin=( $(netstat -r -n | grep -m1 "$interface") )
        gateway=${lin[1]}
        printf '%b' "\n${fg_green}>> Gateway Padrão da interface [${end}$interface${fg_green}]:${end} ${gateway}\n"
    # Prefixo
        octetos=( ${gateway//'.'/' '} )
        prefixo="${octetos[0]}.${octetos[1]}.${octetos[2]}"
        printf '%b' "${fg_green}>> Prefixo da rede:${end} ${prefixo}\n"
    # IPs conectados
        printf '%b' "${fg_green}>> Pesquisando IPs conectados à rede...${end}\n"
        ips=( $(nmap -sP -n -T5 --exclude "$gateway" "$prefixo.0-255" | grep "Nmap scan report for " | cut -d " " -f5) )

        printf '%b' "${fg_green}>> Identificando dispositivos conectados à rede...${end}\n"    
        printf '%b' "${fg_cyan}${linha_tracos}${linha_tracos}\n"   
        printf '%b' "\tIP\t->\tDispositivo\n"
        printf '%b' "${linha_tracos}${linha_tracos}${end}\n"
        i="0"
        for ip in ${ips[@]}; do
            printf '%b' " ${ips[$i]}\t${fg_cyan}->${end}    "
            nome="nenhum"

            for inet in ${inets[@]}; do
                # Se o ip pesquisado for do próprio computador
                [ "$ip" = "$inet" ] && nome=$(uname -n)                
            done
            
            #Obtém o nome do Dispositivo do Ip    
            if [ $nome = "nenhum" ]; then
                nome=$(nmblookup -A "$ip" | grep -m1 "<00>" | cut -d " " -f1)
            fi
            
            # Se o cliente não fornecer o nome do Computador, 
            if [ -z "$nome" ]; then
                # Nome do Fabricante da placa de rede do cliente        
                nome=$(nmap -sP -n $ip | grep "MAC Address: " | cut -d "(" -f2 | sed 's/ /_/g; s/)//g')
            fi

            printf '%b' "${nome}\n" 
            let i++
        done

        printf '%b' "${fg_cyan}${linha_tracos}${linha_tracos}${end}\n"