class BlockNumberTracker {
    public static volatile int latestBlock;
    private static volatile boolean processedLastBlock;
    public BlockNumberTracker(int n) {
        this.latestBlock = n;
        this.processedLastBlock = false;
    }

    public synchronized void incrementBlock() {
        latestBlock++;
    }

    public synchronized boolean gotLastBlock() {
        return processedLastBlock;
    }

    public synchronized void setLastBlock(boolean bool) {
        processedLastBlock = bool;
    }
}