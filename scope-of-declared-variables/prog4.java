public class prog4 {
    public static void main(String argv[]) {
	//int i;                            // line 1
	int in1, in2, out1, out2, out3;

	if (argv.length != 3) {
	    System.err.printf("usage: %s <in1> <in2>\n", argv[0]);
	    System.exit(1);
	}
	in1 = Integer.parseInt(argv[1]);
	in2 = Integer.parseInt(argv[2]);

	//i = in1;                      // line 2
	{
	    // $ javac prog1.java
            // prog4.java:20: error: variable i might not have been initialized
            //             int i = i;                // line 3
            //                     ^
            // 1 error
            int i = i;                // line 3
            int j = i + 1;            // line 4
	    out2 = i;                 // line 5
	    out3 = j;                 // line 6
	}
	out1 = in1;                   // line 7
	System.out.printf("out1=%d out2=%d out3=%d\n", out1, out2, out3);
    }
}
