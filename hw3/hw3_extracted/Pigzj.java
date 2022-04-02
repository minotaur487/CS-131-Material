import java.io.IOException;

class Pigzj {
    private int maxThreads;
    private Runtime runtime;

    public Pigzj(String[] args) throws IOException  {
        this.runtime = Runtime.getRuntime();
        this.maxThreads = runtime.availableProcessors();

        int numberOfThreads = processArguments(args);
        MultiThreadedGZipCompressor multi_compress = new MultiThreadedGZipCompressor(numberOfThreads);
        multi_compress.compress();
    }

    public int processArguments(String[] args) {
        int length = args.length;
        boolean hasSetProcessors = false;
        int numberOfChosenProcessers = -1;
        int convertedArg = -1;

        if (length == 0)
            return maxThreads;

        for (int i = 0; i < length; i++) {
            String curArg = args[i];
            switch (curArg) {
                case "-p":
                    hasSetProcessors = true;
                break;
                default:
                    if (hasSetProcessors) {
                        try {
                            convertedArg = Integer.parseInt(curArg, 10);
                        } catch (NumberFormatException e) {
                            System.err.println("A valid number must be used with option -p.");
                            System.exit(-1);
                        }
                        
                        if (convertedArg < 1) {
                            System.err.println("Number of procesors requested can\'t be negative.");
                            System.exit(-1);
                        }
                        numberOfChosenProcessers = convertedArg;
                    } else {
                        System.err.println("Invalid options.");
                        System.exit(-1);
                    }
            }
        }
        if (numberOfChosenProcessers > (4 * maxThreads)) {
            System.err.println("Number of processors requested is too big.");
            System.exit(-1);
        }
        else if (numberOfChosenProcessers < 0) {
            System.err.println("Number of procesors requested can\'t be negative.");
            System.exit(-1);
        }
        return numberOfChosenProcessers;           
    }

    public static void main(String[] args) throws IOException {
        new Pigzj(args);
    }
}