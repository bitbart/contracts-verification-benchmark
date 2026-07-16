function check_no_deadlock() public {
    
    require(address(this).balance > 0);
    
    require(donation[address(this)] > 0);

    bool donateSuccess;
    bool withdrawSuccess;
    bool reclaimSuccess;

    try this.donate{value: 0}() {
        donateSuccess = true;
    } catch {
        donateSuccess = false;
    }

    try this.withdraw() {
        withdrawSuccess = true;
    } catch {
        withdrawSuccess = false;
    }

    try this.reclaim() {
        reclaimSuccess = true;
    } catch {
        reclaimSuccess = false;
    }

    assert(donateSuccess || withdrawSuccess || reclaimSuccess);
}
