use std::env;

fn foo(i: i32, out1: &mut i32, out2: &mut i32, out3: &mut i32) {
    let i = i + 1;
    *out1 = i;
    {
        let i = i + 1;
        *out2 = i;
    }
    *out3 = i;
}

fn main() {
    let mut in1: i32 = 0;
    let mut out1: i32 = 0;
    let mut out2: i32 = 0;
    let mut out3: i32 = 0;

    let args: Vec<String> = env::args().collect();
    if args.len() < 2 {
        eprintln!("Please provide two integers as arguments.");
        return;
    }
    match args[1].parse::<i32>() {
        Ok(number) => in1 = number,
        Err(_) => eprintln!("Error: '{}' is not a valid integer.", args[1]),
    }

    let i = in1;
    foo(i, &mut out1, &mut out2, &mut out3);
    println!("out1={} out2={} out3={}", out1, out2, out3);
}
