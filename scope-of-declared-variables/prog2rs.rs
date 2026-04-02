use std::env;

fn main() {
    let mut in1: i32 = 0;
    let mut in2: i32 = 0;
    let out1: i32;
    let out2: i32;
    let out3: i32;

    let args: Vec<String> = env::args().collect();
    if args.len() < 3 {
        eprintln!("Please provide two integers as arguments.");
        return;
    }
    match args[1].parse::<i32>() {
        Ok(number) => in1 = number,
        Err(_) => eprintln!("Error: '{}' is not a valid integer.", args[1]),
    }
    match args[2].parse::<i32>() {
        Ok(number) => in2 = number,
        Err(_) => eprintln!("Error: '{}' is not a valid integer.", args[2]),
    }

    let i = in1;                  // line 2
    {
        let i = in2;              // line 3
        let j = i + 1;            // line 4
        out2 = i;                 // line 5
        out3 = j;                 // line 6
    }
    out1 = i;                     // line 7
    println!("out1={} out2={} out3={}", out1, out2, out3);
}
