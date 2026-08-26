class Foo {
    int a;
    Foo(int val) {
	a = val;
    }
    int set1(int new_val) {
	int cur_val = a;
	a = new_val;
	return cur_val;
    }
    int set2(int new_val) {
	System.out.println("here #1 new_val=" + new_val + " a=" + a);
	int cur_val = a;
	int a = 7;
	System.out.println("here #2 a=" + a);
	a = new_val;
	return cur_val;
    }
    int get() {
	return a;
    }
}

public class prog5 {
    public static void main(String argv[]) {
	//int i;                            // line 1
	int in1, in2, out1, out2, out3;

	System.out.println("argv.length=" + argv.length);
	for (int j = 0; j < argv.length; j++) {
	    System.out.println("  argv[" + j + "]='" + argv[j] + "'");
	}
	if (argv.length != 2) {
	    System.err.printf("usage: <progname> <in1> <in2>\n");
	    System.exit(1);
	}
	in1 = Integer.parseInt(argv[0]);
	in2 = Integer.parseInt(argv[1]);

	Foo foo1 = new Foo(in1);
	Foo foo2 = new Foo(in2);
	foo1.set1(3);
	foo2.set2(4);
	out1 = foo1.get();
	out2 = foo2.get();
	System.out.printf("out1=%d out2=%d\n", out1, out2);
    }
}
