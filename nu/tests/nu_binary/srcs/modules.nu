use nu/tests/modules/math.nu add

if ((add 1 2) != 3) {
    error make {msg: "Things don't add up!"}
}
