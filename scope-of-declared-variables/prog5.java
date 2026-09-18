public class prog5 {
    public static void foo(int i, int[] out) {
	// $ javac prog5.java
        // prog5.java:11: error: variable i is already defined in method foo(int,int[])
        // 	int i = i + 1;
        // 	    ^
        // prog5.java:14: error: variable i is already defined in method foo(int,int[])
        // 	    int i = i + 1;
        // 	        ^
        // 2 errors
	int i = i + 1;
	out[1] = i;
	{
	    int i = i + 1;
	    out[2] = i;
	}
	out[3] = i;
    }

    public static void main(String argv[]) {
	int in1;
	int[] out = new int[4];

	if (argv.length != 2) {
	    System.err.printf("usage: %s <in1>\n", argv[0]);
	    System.exit(1);
	}
	in1 = Integer.parseInt(argv[1]);

	int i = in1;
	foo(i, out);
	System.out.printf("out1=%d out2=%d out3=%d\n", out[1], out[2], out[3]);
    }
}
