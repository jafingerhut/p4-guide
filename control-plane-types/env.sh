P4C_INSTALL=${HOME}/p4c
P4SPEC_INSTALL=${HOME}/p4-spec
P4TEST=${P4C_INSTALL}/build/p4test

translate_p414_to_p416() {
    p4_14_file=$1
    p4_16_file=$2
    ${P4TEST} -I ${P4C_INSTALL}/p4include --p4v 14 --pp ${p4_16_file} ${p4_14_file}
}

gen_p4info() {
    p4_16_file=$1
    p4info_file=$2
    echo "${P4TEST} --p4runtime-format json --p4runtime-file ${p4info_file} ${p4_16_file}"
    ${P4TEST} --p4runtime-format json --p4runtime-file ${p4info_file} ${p4_16_file}
}
