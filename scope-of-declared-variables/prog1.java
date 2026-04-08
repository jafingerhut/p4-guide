public class prog1 {
    public static void main(String argv[]) {
	int i;                            // line 1
	int in1, in2, out1, out2, out3;

	if (argv.length != 3) {
	    System.err.printf("usage: %s <in1> <in2>\n", argv[0]);
	    System.exit(1);
	}
	in1 = Integer.parseInt(argv[1]);
	in2 = Integer.parseInt(argv[2]);

	i = in1;                      // line 2
	{
	    int j = i + 1;            // line 3
	    // $ javac prog1.java
	    // prog1.java:21: error: variable i is already defined in method main(String[])
	    // 	    int i = in2;              // line 4
	    // 	        ^
	    // 1 error
	    int i = in2;              // line 4
	    out2 = i;                 // line 5
	    out3 = j;                 // line 6
	}
	out1 = i;                     // line 7
	System.out.printf("out1=%d out2=%d out3=%d\n", out1, out2, out3);
    }
}
