use std::env;

fn foo(i: i32, o1: &mut i32, o2: &mut i32, o3: &mut i32) {
    let i = i + 1;
    *o1 = i;
    {
        let i = i + 1;
        *o2 = i;
    }
    *o3 = i;
}

fn main() {
    let mut in1: i32 = 0;
    let mut o1: i32 = 0;
    let mut o2: i32 = 0;
    let mut o3: i32 = 0;

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
    foo(i, &mut o1, &mut o2, &mut o3);
    println!("o1={} o2={} o3={}", o1, o2, o3);
}
