methods {
    function releasable(address) external returns (uint256) envfree;
    function release(address) external;

    function isPayee(address) external returns (bool) envfree;
    function getBalance() external returns (uint256) envfree;
    function getTotalReleasable() external returns (uint256) envfree;
    function getPayee(uint256) external returns (address) envfree;
    function getShares(address) external returns (uint256) envfree;
    function getReleased(address) external returns (uint256) envfree;
    function getSumOfShares() external returns (uint256) envfree;
    function getSumOfReleased() external returns (uint256) envfree;
    function getPayeesLength() external returns (uint256) envfree;
    function getTotalShares() external returns (uint256) envfree;
    function getTotalReleased() external returns (uint256) envfree;
}
