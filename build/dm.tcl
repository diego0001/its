log_progress "ENTERING BUILD SCRIPT: DM"

# This build script is for programs particular to the
# Dynamic Modeling PDP-10.

# Demon starter.
respond "*" ":midas sys; atsign demstr_sysen2; demstr\r"
expect ":KILL"

# Demon status.  Self purifying.
respond "*" ":midas sysen2; ts demst_sysen2; demst\r"
expect ":KILL"

# Gun down dead demons.
respond "*" ":link taa; pwfile 999999, sysen1; pwfile >\r"
type ":vk\r"
respond "*" ":midas sys; atsign gunner_sysen2; gunner\r"
expect ":KILL"

# Line printer unspooler demon.
respond "*" ":midas sys; atsign unspoo_sysen1; unspoo\r"
# Just accept the defaults for now.
respond "(CR) FOR DEVICE LPT, nn FOR Tnn" "\r"
respond "(CR) FOR .LPTR. DIRECTORY, OR TYPE NEW NAME" "\r"
expect ":KILL"

# Arpanet survey demon.
respond "*" ":midas sys; atsign survey_survey; survey\r"
expect ":KILL"

# Survey giver demon.
respond "*" ":midas survey; atsign surgiv_surgiv\r"
expect ":KILL"
respond "*" ":link sys; atsign surgiv, survey;\r"
type ":vk\r"

# Survey sender demon.
respond "*" ":link sys; atsign sursnd, survey;\r"
type ":vk\r"

set loc 2

proc dm_password {user pass} {
    global loc
    respond "*" ":job pw\r"
    respond "*" "$loc/"
    set loc [expr $loc + 1]
    respond "0" "\0331'$user\033\r"
    respond "\n" ":job booter\r"
    respond "*" "start/"
    respond "MOVE P," "\033q\033x"
    respond "*" "a/"
    expect  "   "
    respond "   " "\0331'$pass\033\r"
    respond "\n" ":go scramble\r"
    expect "ILOPR"
    respond "0>>0" "a/"
    respond "   " ":job pw\r"
    respond "*" "$loc/"
    set loc [expr $loc + 1]
    respond "0" "\0331q\r"
    respond "\n" ":vk\r"
}

# Login program.
respond "*" ":midas sysbin;_syseng; booter\r"
expect ":KILL"

# Enter users into the password file.
respond "*" ":job pw\r"
respond "*" ":job booter\r"
respond "*" ":load sysbin;\r"
# Enter an empty password for AS.
dm_password "AS" ""
respond "*" "\033y"
respond " " "sys;\021 \021 pass \021 words\r"
respond "*" ":kill\r"
respond "*" ":kill\r"
mkdir "(init)"
respond "*" ":link (init); as hactrn, sys2; ts shell\r"
type ":vk\r"
