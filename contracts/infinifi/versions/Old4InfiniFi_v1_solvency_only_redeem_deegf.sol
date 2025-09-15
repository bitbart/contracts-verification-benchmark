--- START FILE: ../infinify_certora_report/src/farms/SwapFarm.sol ---
pragma solidity 0.8.28;
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {FixedPointMathLib} from "@solmate/src/utils/FixedPointMathLib.sol";
import {Farm} from "@integrations/Farm.sol";
import {IOracle} from "@interfaces/IOracle.sol";
import {CoreRoles} from "@libraries/CoreRoles.sol";
import {Accounting} from "@finance/Accounting.sol";
import {IMaturityFarm, IFarm} from "@interfaces/IMaturityFarm.sol";
contract SwapFarm is Farm, IMaturityFarm {
    using SafeERC20 for IERC20;
    using FixedPointMathLib for uint256;
    error SwapFailed(bytes returnData);
    error SwapCooldown();
    error RouterNotEnabled(address router);
    address public immutable wrapToken;
    address public immutable accounting;
    uint256 private immutable duration;
    mapping(address => bool) public enabledRouters;
    uint256 public lastSwap = 1;
    uint256 public constant _SWAP_COOLDOWN = 4 hours;
    constructor(address _core, address _assetToken, address _wrapToken, address _accounting, uint256 _duration)
        Farm(_core, _assetToken)
    {
        wrapToken = _wrapToken;
        accounting = _accounting;
        duration = _duration;
        maxSlippage = 0.995e18;
    }
    function maturity() public view override returns (uint256) {
        return block.timestamp + duration;
    }
    function assets() public view virtual override(Farm, IFarm) returns (uint256) {
        uint256 assetTokenBalance = IERC20(assetToken).balanceOf(address(this));
        uint256 wrapTokenAssetsValue = convertToAssets(IERC20(wrapToken).balanceOf(address(this)));
        return assetTokenBalance + wrapTokenAssetsValue;
    }
    function liquidity() public view override returns (uint256) {
        return IERC20(assetToken).balanceOf(address(this));
    }
    function setEnabledRouter(address _router, bool _enabled) external onlyCoreRole(CoreRoles.PROTOCOL_PARAMETERS) {
        enabledRouters[_router] = _enabled;
    }
    function _deposit(uint256) internal view override {}
    function deposit() external view override(Farm, IFarm) onlyCoreRole(CoreRoles.FARM_MANAGER) whenNotPaused {}
    function _withdraw(uint256 _amount, address _to) internal override {
        IERC20(assetToken).safeTransfer(_to, _amount);
    }
    function convertToAssets(uint256 _wrapTokenAmount) public view returns (uint256) {
        uint256 assetTokenPrice = Accounting(accounting).price(assetToken);
        uint256 wrapTokenPrice = Accounting(accounting).price(wrapToken);
        return _wrapTokenAmount.mulDivDown(wrapTokenPrice, assetTokenPrice);
    }
    function wrapAssets(uint256 _assetsIn, address _router, bytes memory _calldata)
        external
        whenNotPaused
        onlyCoreRole(CoreRoles.FARM_SWAP_CALLER)
    {
        require(enabledRouters[_router], RouterNotEnabled(_router));
        require(block.timestamp > lastSwap + _SWAP_COOLDOWN, SwapCooldown());
        lastSwap = block.timestamp;
        uint256 wrapTokenBalanceBefore = IERC20(wrapToken).balanceOf(address(this));
        IERC20(assetToken).forceApprove(_router, _assetsIn);
        (bool success, bytes memory returnData) = _router.call(_calldata);
        require(success, SwapFailed(returnData));
        uint256 wrapTokenReceived = IERC20(wrapToken).balanceOf(address(this)) - wrapTokenBalanceBefore;
        uint256 minAssetsOut = _assetsIn.mulWadDown(maxSlippage);
        uint256 assetsReceived = convertToAssets(wrapTokenReceived);
        require(assetsReceived >= minAssetsOut, SlippageTooHigh(minAssetsOut, assetsReceived));
        _afterWrap(wrapTokenReceived);
    }
    function _afterWrap(uint256  ) internal virtual {}
    function unwrapAssets(uint256 _wrapTokenAmount, address _router, bytes memory _calldata)
        external
        whenNotPaused
        onlyCoreRole(CoreRoles.FARM_SWAP_CALLER)
    {
        require(enabledRouters[_router], RouterNotEnabled(_router));
        require(block.timestamp > lastSwap + _SWAP_COOLDOWN, SwapCooldown());
        lastSwap = block.timestamp;
        uint256 assetsBefore = IERC20(assetToken).balanceOf(address(this));
        _beforeUnwrap(_wrapTokenAmount);
        IERC20(wrapToken).forceApprove(_router, _wrapTokenAmount);
        (bool success, bytes memory returnData) = _router.call(_calldata);
        require(success, SwapFailed(returnData));
        uint256 assetsReceived = IERC20(assetToken).balanceOf(address(this)) - assetsBefore;
        uint256 minAssetsOut = convertToAssets(_wrapTokenAmount).mulWadDown(maxSlippage);
        require(assetsReceived >= minAssetsOut, SlippageTooHigh(minAssetsOut, assetsReceived));
    }
    function _beforeUnwrap(uint256  ) internal virtual {}
}
--- END FILE: ../infinify_certora_report/src/farms/SwapFarm.sol ---
--- START FILE: ../infinify_certora_report/src/farms/AaveV3Farm.sol ---
pragma solidity 0.8.28;
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Farm} from "@integrations/Farm.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {CoreRoles} from "@libraries/CoreRoles.sol";
import {IAaveV3Pool} from "@interfaces/aave/IAaveV3Pool.sol";
import {IAddressProvider} from "@interfaces/aave/IAddressProvider.sol";
import {IAaveDataProvider} from "@interfaces/aave/IAaveDataProvider.sol";
contract AaveV3Farm is Farm {
    using SafeERC20 for IERC20;
    error ZeroAddress(address);
    event LendingPoolUpdated(uint256 indexed timestamp, address lendingPool);
    address public immutable aToken;
    address public lendingPool;
    constructor(address _aToken, address _aaveV3Pool, address _core, address _assetToken) Farm(_core, _assetToken) {
        aToken = _aToken;
        lendingPool = _aaveV3Pool;
    }
    function setLendingPool(address _lendingPool) external onlyCoreRole(CoreRoles.GOVERNOR) {
        require(lendingPool != address(0), ZeroAddress(_lendingPool));
        lendingPool = _lendingPool;
        emit LendingPoolUpdated(block.timestamp, _lendingPool);
    }
    function assets() public view override returns (uint256) {
        return ERC20(aToken).balanceOf(address(this));
    }
    function liquidity() public view override returns (uint256) {
        uint256 totalAssets = assets();
        address dataProvider = IAddressProvider(IAaveV3Pool(lendingPool).ADDRESSES_PROVIDER()).getPoolDataProvider();
        bool isAavePaused = IAaveDataProvider(dataProvider).getPaused(assetToken);
        if (isAavePaused) return 0;
        uint256 availableLiquidity = ERC20(assetToken).balanceOf(aToken);
        return availableLiquidity < totalAssets ? availableLiquidity : totalAssets;
    }
    function _deposit(uint256 availableBalance) internal override {
        IERC20(assetToken).forceApprove(address(lendingPool), availableBalance);
        IAaveV3Pool(lendingPool).supply(assetToken, availableBalance, address(this), 0);
    }
    function _withdraw(uint256 _amount, address _to) internal override {
        IAaveV3Pool(lendingPool).withdraw(assetToken, _amount, _to);
    }
}
--- END FILE: ../infinify_certora_report/src/farms/AaveV3Farm.sol ---
--- START FILE: ../infinify_certora_report/src/farms/PendleV2Farm.sol ---
pragma solidity 0.8.28;
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {FixedPointMathLib} from "@solmate/src/utils/FixedPointMathLib.sol";
import {IOracle} from "@interfaces/IOracle.sol";
import {ISYToken} from "@interfaces/pendle/ISYToken.sol";
import {CoreRoles} from "@libraries/CoreRoles.sol";
import {Accounting} from "@finance/Accounting.sol";
import {Farm, IFarm} from "@integrations/Farm.sol";
import {IPendleMarket} from "@interfaces/pendle/IPendleMarket.sol";
import {IPendleOracle} from "@interfaces/pendle/IPendleOracle.sol";
import {IMaturityFarm, IFarm} from "@interfaces/IMaturityFarm.sol";
contract PendleV2Farm is Farm, IMaturityFarm {
    using SafeERC20 for IERC20;
    using FixedPointMathLib for uint256;
    error PTAlreadyMatured(uint256 maturity);
    error PTNotMatured(uint256 maturity);
    error SwapFailed(bytes reason);
    uint256 public immutable maturity;
    address public immutable pendleMarket;
    address public immutable pendleOracle;
    uint32 private constant _PENDLE_ORACLE_TWAP_DURATION = 3600;
    address public immutable underlyingToken;
    address public immutable ptToken;
    address public immutable syToken;
    address public immutable accounting;
    address public pendleRouter;
    uint256 private totalWrappedAssets;
    uint256 private totalUnwrappedAssets;
    uint256 private totalReceivedPTs;
    uint256 private totalRedeemedPTs;
    uint256 private _alreadyInterpolatedYield;
    uint256 private _lastWrappedTimestamp;
    constructor(address _core, address _assetToken, address _pendleMarket, address _pendleOracle, address _accounting)
        Farm(_core, _assetToken)
    {
        pendleMarket = _pendleMarket;
        pendleOracle = _pendleOracle;
        accounting = _accounting;
        (syToken, ptToken,) = IPendleMarket(_pendleMarket).readTokens();
        (, underlyingToken,) = ISYToken(syToken).assetInfo();
        maturity = IPendleMarket(_pendleMarket).expiry();
        maxSlippage = 0.995e18;
    }
    function setPendleRouter(address _pendleRouter) external onlyCoreRole(CoreRoles.PROTOCOL_PARAMETERS) {
        pendleRouter = _pendleRouter;
    }
    function assets() public view override(Farm, IFarm) returns (uint256) {
        uint256 assetTokenBalance = IERC20(assetToken).balanceOf(address(this));
        if (block.timestamp < maturity) {
            return assetTokenBalance + totalWrappedAssets + _interpolatingYield();
        } else {
            uint256 balanceOfPTs = IERC20(ptToken).balanceOf(address(this));
            uint256 ptAssetsValue = 0;
            if (balanceOfPTs > 0) {
                ptAssetsValue = _ptToAssets(balanceOfPTs).mulWadDown(maxSlippage);
            }
            return assetTokenBalance + ptAssetsValue;
        }
    }
    function liquidity() public view override returns (uint256) {
        return IERC20(assetToken).balanceOf(address(this));
    }
    function wrapAssetToPt(uint256 _assetsIn, bytes memory _calldata)
        external
        whenNotPaused
        onlyCoreRole(CoreRoles.FARM_SWAP_CALLER)
    {
        require(block.timestamp < maturity, PTAlreadyMatured(maturity));
        _alreadyInterpolatedYield = _interpolatingYield();
        uint256 ptBalanceBefore = IERC20(ptToken).balanceOf(address(this));
        IERC20(assetToken).forceApprove(pendleRouter, _assetsIn);
        (bool success, bytes memory reason) = pendleRouter.call(_calldata);
        require(success, SwapFailed(reason));
        uint256 ptBalanceAfter = IERC20(ptToken).balanceOf(address(this));
        uint256 ptReceived = ptBalanceAfter - ptBalanceBefore;
        uint256 minAssetsOut = _assetsIn.mulWadDown(maxSlippage);
        require(_ptToAssets(ptReceived) >= minAssetsOut, SlippageTooHigh(minAssetsOut, _ptToAssets(ptReceived)));
        totalWrappedAssets += _assetsIn;
        totalReceivedPTs += ptReceived;
        _lastWrappedTimestamp = block.timestamp;
    }
    function unwrapPtToAsset(uint256 _ptTokensIn, bytes memory _calldata)
        external
        whenNotPaused
        onlyCoreRole(CoreRoles.FARM_SWAP_CALLER)
    {
        require(block.timestamp >= maturity, PTNotMatured(maturity));
        uint256 assetsBefore = IERC20(assetToken).balanceOf(address(this));
        IERC20(ptToken).forceApprove(pendleRouter, _ptTokensIn);
        (bool success, bytes memory reason) = pendleRouter.call(_calldata);
        require(success, SwapFailed(reason));
        uint256 assetsAfter = IERC20(assetToken).balanceOf(address(this));
        uint256 assetsReceived = assetsAfter - assetsBefore;
        uint256 minAssetsOut = _ptToAssets(_ptTokensIn).mulWadDown(maxSlippage);
        require(assetsReceived >= minAssetsOut, SlippageTooHigh(minAssetsOut, assetsReceived));
        totalUnwrappedAssets += assetsReceived;
        totalRedeemedPTs += _ptTokensIn;
    }
    function _deposit(uint256) internal view override {}
    function deposit() external view override(Farm, IFarm) onlyCoreRole(CoreRoles.FARM_MANAGER) whenNotPaused {
        require(block.timestamp < maturity, PTAlreadyMatured(maturity));
    }
    function _withdraw(uint256 _amount, address _to) internal override {
        IERC20(assetToken).safeTransfer(_to, _amount);
    }
    function _assetToPtUnderlyingRate() internal view returns (uint256) {
        uint256 assetPrice = Accounting(accounting).price(assetToken);
        uint256 underlyingPrice = Accounting(accounting).price(underlyingToken);
        return underlyingPrice.divWadDown(assetPrice);
    }
    function _ptToAssets(uint256 _ptAmount) internal view returns (uint256) {
        uint256 ptToUnderlyingRate =
            IPendleOracle(pendleOracle).getPtToAssetRate(pendleMarket, _PENDLE_ORACLE_TWAP_DURATION);
        uint256 ptUnderlying = _ptAmount.mulWadDown(ptToUnderlyingRate);
        return ptUnderlying.mulWadDown(_assetToPtUnderlyingRate());
    }
    function _interpolatingYield() internal view returns (uint256) {
        if (_lastWrappedTimestamp == 0) return 0;
        uint256 balanceOfPTs = IERC20(ptToken).balanceOf(address(this));
        if (balanceOfPTs == 0) return 0;
        uint256 maturityAssetAmount = balanceOfPTs.mulWadDown(_assetToPtUnderlyingRate());
        maturityAssetAmount = maturityAssetAmount.mulWadDown(maxSlippage);
        int256 totalYieldRemainingToInterpolate =
            int256(maturityAssetAmount) - int256(totalWrappedAssets) - int256(_alreadyInterpolatedYield);
        if (totalYieldRemainingToInterpolate < 0) return _alreadyInterpolatedYield;
        uint256 yieldPerSecond =
            uint256(totalYieldRemainingToInterpolate) * FixedPointMathLib.WAD / (maturity - _lastWrappedTimestamp);
        uint256 secondsSinceLastWrap = block.timestamp - _lastWrappedTimestamp;
        uint256 interpolatedYield = yieldPerSecond * secondsSinceLastWrap;
        return _alreadyInterpolatedYield + interpolatedYield / FixedPointMathLib.WAD;
    }
}
--- END FILE: ../infinify_certora_report/src/farms/PendleV2Farm.sol ---
--- START FILE: ../infinify_certora_report/src/farms/ERC4626Farm.sol ---
pragma solidity 0.8.28;
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Farm} from "@integrations/Farm.sol";
contract ERC4626Farm is Farm {
    using SafeERC20 for IERC20;
    error AssetMismatch(address _assetToken, address _vaultAsset);
    address public immutable vault;
    constructor(address _core, address _assetToken, address _vault) Farm(_core, _assetToken) {
        vault = _vault;
        require(ERC4626(vault).asset() == _assetToken, AssetMismatch(_assetToken, ERC4626(vault).asset()));
    }
    function assets() public view override returns (uint256) {
        uint256 vaultShares = ERC20(vault).balanceOf(address(this));
        return ERC4626(vault).convertToAssets(vaultShares);
    }
    function liquidity() public view virtual override returns (uint256) {
        return ERC4626(vault).maxWithdraw(address(this));
    }
    function _deposit(uint256 availableAssets) internal override {
        IERC20(assetToken).forceApprove(vault, availableAssets);
        ERC4626(vault).deposit(availableAssets, address(this));
    }
    function _withdraw(uint256 _amount, address _to) internal virtual override {
        ERC4626(vault).withdraw(_amount, _to, address(this));
    }
}
--- END FILE: ../infinify_certora_report/src/farms/ERC4626Farm.sol ---
--- START FILE: ../infinify_certora_report/src/tokens/LockedPositionToken.sol ---
pragma solidity 0.8.28;
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {EpochLib} from "@libraries/EpochLib.sol";
import {CoreRoles} from "@libraries/CoreRoles.sol";
import {CoreControlled} from "@core/CoreControlled.sol";
contract LockedPositionToken is CoreControlled, ERC20Permit, ERC20Burnable {
    error TransferRestrictedUntil(address user, uint256 timestamp);
    mapping(address => uint256) public transferRestrictions;
    constructor(address _core, string memory _name, string memory _symbol)
        CoreControlled(_core)
        ERC20(_name, _symbol)
        ERC20Permit(_name)
    {}
    function mint(address _to, uint256 _amount) external onlyCoreRole(CoreRoles.LOCKED_TOKEN_MANAGER) {
        _mint(_to, _amount);
    }
    function burn(uint256 _value) public override onlyCoreRole(CoreRoles.LOCKED_TOKEN_MANAGER) {
        _burn(_msgSender(), _value);
    }
    function burnFrom(address _account, uint256 _value) public override onlyCoreRole(CoreRoles.LOCKED_TOKEN_MANAGER) {
        _spendAllowance(_account, _msgSender(), _value);
        _burn(_account, _value);
    }
    function restrictTransferUntilNextEpoch(address _user) external onlyCoreRole(CoreRoles.TRANSFER_RESTRICTOR) {
        transferRestrictions[_user] = EpochLib.epochToTimestamp(EpochLib.nextEpoch(block.timestamp));
    }
    function _update(address _from, address _to, uint256 _value) internal override {
        uint256 restriction = transferRestrictions[_from];
        if (restriction > 0) {
            require(block.timestamp >= restriction, TransferRestrictedUntil(_from, restriction));
        }
        return ERC20._update(_from, _to, _value);
    }
}
--- END FILE: ../infinify_certora_report/src/tokens/LockedPositionToken.sol ---
--- START FILE: ../infinify_certora_report/src/tokens/ReceiptToken.sol ---
pragma solidity 0.8.28;
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {CoreRoles} from "@libraries/CoreRoles.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {CoreControlled} from "@core/CoreControlled.sol";
contract ReceiptToken is CoreControlled, ERC20Permit, ERC20Burnable {
    constructor(address _core, string memory _name, string memory _symbol)
        CoreControlled(_core)
        ERC20(_name, _symbol)
        ERC20Permit(_name)
    {}
    function mint(address _to, uint256 _amount) external onlyCoreRole(CoreRoles.RECEIPT_TOKEN_MINTER) {
        _mint(_to, _amount);
    }
    function burn(uint256 _value) public override onlyCoreRole(CoreRoles.RECEIPT_TOKEN_BURNER) {
        _burn(_msgSender(), _value);
    }
    function burnFrom(address _account, uint256 _value) public override onlyCoreRole(CoreRoles.RECEIPT_TOKEN_BURNER) {
        _spendAllowance(_account, _msgSender(), _value);
        _burn(_account, _value);
    }
}
--- END FILE: ../infinify_certora_report/src/tokens/ReceiptToken.sol ---
--- START FILE: ../infinify_certora_report/src/tokens/StakedToken.sol ---
pragma solidity 0.8.28;
import {EpochLib} from "@libraries/EpochLib.sol";
import {CoreRoles} from "@libraries/CoreRoles.sol";
import {ReceiptToken} from "@tokens/ReceiptToken.sol";
import {YieldSharing} from "@finance/YieldSharing.sol";
import {CoreControlled} from "@core/CoreControlled.sol";
import {ERC20, IERC20, ERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
contract StakedToken is ERC4626, CoreControlled {
    using EpochLib for uint256;
    error PendingLossesUnapplied();
    event VaultLoss(uint256 indexed timestamp, uint256 epoch, uint256 assets);
    event VaultProfit(uint256 indexed timestamp, uint256 epoch, uint256 assets);
    address public yieldSharing;
    mapping(uint256 epoch => uint256 rewards) public epochRewards;
    constructor(address _core, address _receiptToken)
        CoreControlled(_core)
        ERC20(string.concat("Staked ", ERC20(_receiptToken).name()), string.concat("s", ERC20(_receiptToken).symbol()))
        ERC4626(IERC20(_receiptToken))
    {}
    function setYieldSharing(address _yieldSharing) external onlyCoreRole(CoreRoles.GOVERNOR) {
        yieldSharing = _yieldSharing;
    }
    function maxMint(address _receiver) public view override returns (uint256) {
        if (paused()) {
            return 0;
        }
        return super.maxMint(_receiver);
    }
    function maxDeposit(address _receiver) public view override returns (uint256) {
        if (paused()) {
            return 0;
        }
        return super.maxDeposit(_receiver);
    }
    function maxRedeem(address _receiver) public view override returns (uint256) {
        if (paused() || YieldSharing(yieldSharing).unaccruedYield() < 0) {
            return 0;
        }
        return super.maxRedeem(_receiver);
    }
    function maxWithdraw(address _receiver) public view override returns (uint256) {
        if (paused() || YieldSharing(yieldSharing).unaccruedYield() < 0) {
            return 0;
        }
        return super.maxWithdraw(_receiver);
    }
    function _deposit(address caller, address receiver, uint256 assets, uint256 shares) internal override {
        YieldSharing(yieldSharing).getCachedStakedReceiptTokens();
        super._deposit(caller, receiver, assets, shares);
    }
    function _withdraw(address caller, address receiver, address owner, uint256 assets, uint256 shares)
        internal
        override
    {
        YieldSharing(yieldSharing).getCachedStakedReceiptTokens();
        super._withdraw(caller, receiver, owner, assets, shares);
    }
    function applyLosses(uint256 _amount) external onlyCoreRole(CoreRoles.FINANCE_MANAGER) {
        _amount = _slashEpochRewards(block.timestamp.nextEpoch(), _amount);
        if (_amount == 0) return;
        _amount = _slashEpochRewards(block.timestamp.epoch(), _amount);
        if (_amount == 0) return;
        ReceiptToken(asset()).burn(_amount);
        emit VaultLoss(block.timestamp, 0, _amount);
    }
    function _slashEpochRewards(uint256 _epoch, uint256 _amount) internal returns (uint256) {
        uint256 _epochRewards = epochRewards[_epoch];
        if (_epochRewards >= _amount) {
            epochRewards[_epoch] = _epochRewards - _amount;
            ReceiptToken(asset()).burn(_amount);
            emit VaultLoss(block.timestamp, _epoch, _amount);
            _amount = 0;
        } else {
            epochRewards[_epoch] = 0;
            ReceiptToken(asset()).burn(_epochRewards);
            emit VaultLoss(block.timestamp, _epoch, _epochRewards);
            _amount -= _epochRewards;
        }
        return _amount;
    }
    function depositRewards(uint256 _amount) external onlyCoreRole(CoreRoles.FINANCE_MANAGER) {
        ERC20(asset()).transferFrom(msg.sender, address(this), _amount);
        uint256 epoch = block.timestamp.nextEpoch();
        epochRewards[epoch] += _amount;
        emit VaultProfit(block.timestamp, epoch, _amount);
    }
    function _unavailableCurrentEpochRewards() internal view returns (uint256) {
        uint256 currentEpoch = block.timestamp.epoch();
        uint256 currentEpochRewards = epochRewards[currentEpoch]; 
        uint256 elapsed = block.timestamp - currentEpoch.epochToTimestamp();
        uint256 availableEpochRewards = (currentEpochRewards * elapsed) / EpochLib.EPOCH;
        return currentEpochRewards - availableEpochRewards;
    }
    function totalAssets() public view override returns (uint256) {
        return super.totalAssets() - epochRewards[block.timestamp.nextEpoch()] - _unavailableCurrentEpochRewards();
    }
}
--- END FILE: ../infinify_certora_report/src/tokens/StakedToken.sol ---
--- START FILE: ../infinify_certora_report/src/libraries/EpochLib.sol ---
pragma solidity 0.8.28;
library EpochLib {
    uint256 internal constant EPOCH = 1 weeks;
    uint256 internal constant EPOCH_OFFSET = 3 days;
    function epoch(uint256 _timestamp) public pure returns (uint256) {
        return (_timestamp - EPOCH_OFFSET) / EPOCH;
    }
    function nextEpoch(uint256 _timestamp) public pure returns (uint256) {
        return epoch(_timestamp) + 1;
    }
    function epochToTimestamp(uint256 _epoch) public pure returns (uint256) {
        return _epoch * EPOCH + EPOCH_OFFSET;
    }
}
--- END FILE: ../infinify_certora_report/src/libraries/EpochLib.sol ---
--- START FILE: ../infinify_certora_report/src/libraries/RedemptionQueue.sol ---
pragma solidity 0.8.28;
library RedemptionQueue {
    error QueueIsFull();
    error QueueIsEmpty();
    error IndexOutOfBounds(uint256 _index);
    struct RedemptionRequest {
        uint96 amount; 
        address recipient; 
    }
    struct RedemptionRequestsQueue {
        uint128 _begin;
        uint128 _end;
        mapping(uint128 index => RedemptionRequest) _data;
    }
    function pushBack(RedemptionRequestsQueue storage _redemptionRequestsQueue, RedemptionRequest memory _value)
        internal
    {
        unchecked {
            uint128 backIndex = _redemptionRequestsQueue._end;
            if (backIndex + 1 == _redemptionRequestsQueue._begin) {
                revert QueueIsFull();
            }
            _redemptionRequestsQueue._data[backIndex] = _value;
            _redemptionRequestsQueue._end = backIndex + 1;
        }
    }
    function popFront(RedemptionRequestsQueue storage _redemptionRequestsQueue)
        internal
        returns (RedemptionRequest memory)
    {
        unchecked {
            uint128 frontIndex = _redemptionRequestsQueue._begin;
            if (frontIndex == _redemptionRequestsQueue._end) {
                revert QueueIsEmpty();
            }
            RedemptionRequest memory value = _redemptionRequestsQueue._data[frontIndex];
            delete _redemptionRequestsQueue._data[frontIndex];
            _redemptionRequestsQueue._begin = frontIndex + 1;
            return value;
        }
    }
    function updateFront(RedemptionRequestsQueue storage _redemptionRequestsQueue, uint96 _newAmount) internal {
        if (empty(_redemptionRequestsQueue)) {
            revert QueueIsEmpty();
        }
        _redemptionRequestsQueue._data[_redemptionRequestsQueue._begin].amount = _newAmount;
    }
    function front(RedemptionRequestsQueue storage _redemptionRequestsQueue)
        internal
        view
        returns (RedemptionRequest memory)
    {
        if (empty(_redemptionRequestsQueue)) {
            revert QueueIsEmpty();
        }
        return _redemptionRequestsQueue._data[_redemptionRequestsQueue._begin];
    }
    function length(RedemptionRequestsQueue storage _redemptionRequestsQueue) internal view returns (uint256) {
        unchecked {
            return uint256(_redemptionRequestsQueue._end - _redemptionRequestsQueue._begin);
        }
    }
    function at(RedemptionRequestsQueue storage _redemptionRequestsQueue, uint256 _index)
        internal
        view
        returns (RedemptionRequest memory)
    {
        if (_index >= length(_redemptionRequestsQueue)) {
            revert IndexOutOfBounds(_index);
        }
        unchecked {
            return _redemptionRequestsQueue._data[_redemptionRequestsQueue._begin + uint128(_index)];
        }
    }
    function empty(RedemptionRequestsQueue storage _redemptionRequestsQueue) internal view returns (bool) {
        return _redemptionRequestsQueue._end == _redemptionRequestsQueue._begin;
    }
}
--- END FILE: ../infinify_certora_report/src/libraries/RedemptionQueue.sol ---
--- START FILE: ../infinify_certora_report/src/libraries/CoreRoles.sol ---
pragma solidity 0.8.28;
library CoreRoles {
    bytes32 internal constant GOVERNOR = keccak256("GOVERNOR");
    bytes32 internal constant PAUSE = keccak256("PAUSE");
    bytes32 internal constant UNPAUSE = keccak256("UNPAUSE");
    bytes32 internal constant PROTOCOL_PARAMETERS = keccak256("PROTOCOL_PARAMETERS");
    bytes32 internal constant MINOR_ROLES_MANAGER = keccak256("MINOR_ROLES_MANAGER");
    bytes32 internal constant ENTRY_POINT = keccak256("ENTRY_POINT");
    bytes32 internal constant RECEIPT_TOKEN_MINTER = keccak256("RECEIPT_TOKEN_MINTER");
    bytes32 internal constant RECEIPT_TOKEN_BURNER = keccak256("RECEIPT_TOKEN_BURNER");
    bytes32 internal constant LOCKED_TOKEN_MANAGER = keccak256("LOCKED_TOKEN_MANAGER");
    bytes32 internal constant TRANSFER_RESTRICTOR = keccak256("TRANSFER_RESTRICTOR");
    bytes32 internal constant FARM_MANAGER = keccak256("FARM_MANAGER");
    bytes32 internal constant MANUAL_REBALANCER = keccak256("MANUAL_REBALANCER");
    bytes32 internal constant PERIODIC_REBALANCER = keccak256("PERIODIC_REBALANCER");
    bytes32 internal constant EMERGENCY_WITHDRAWAL = keccak256("EMERGENCY_WITHDRAWAL");
    bytes32 internal constant FARM_SWAP_CALLER = keccak256("FARM_SWAP_CALLER");
    bytes32 internal constant ORACLE_MANAGER = keccak256("ORACLE_MANAGER");
    bytes32 internal constant FINANCE_MANAGER = keccak256("FINANCE_MANAGER");
    bytes32 internal constant PROPOSER_ROLE = keccak256("PROPOSER_ROLE");
    bytes32 internal constant EXECUTOR_ROLE = keccak256("EXECUTOR_ROLE");
    bytes32 internal constant CANCELLER_ROLE = keccak256("CANCELLER_ROLE");
}
--- END FILE: ../infinify_certora_report/src/libraries/CoreRoles.sol ---
--- START FILE: ../infinify_certora_report/src/governance/AllocationVoting.sol ---
pragma solidity 0.8.28;
import {FixedPointMathLib} from "@solmate/src/utils/FixedPointMathLib.sol";
import {IFarm} from "@interfaces/IFarm.sol";
import {EpochLib} from "@libraries/EpochLib.sol";
import {CoreRoles} from "@libraries/CoreRoles.sol";
import {FarmTypes} from "@libraries/FarmTypes.sol";
import {FarmRegistry} from "@integrations/FarmRegistry.sol";
import {IMaturityFarm} from "@interfaces/IMaturityFarm.sol";
import {CoreControlled} from "@core/CoreControlled.sol";
import {LockingController} from "@locking/LockingController.sol";
import {LockedPositionToken} from "@tokens/LockedPositionToken.sol";
contract AllocationVoting is CoreControlled {
    using EpochLib for uint256;
    using FixedPointMathLib for uint256;
    error InvalidAsset(address _asset);
    error AlreadyVoted(address _user, uint32 _unwindingEpochs);
    error NoVotingPower(address _user, uint32 _unwindingEpochs);
    error UnknownFarm(address farm, bool liquid);
    error InvalidWeights(uint256 _expectedPower, uint256 _actualPower);
    error InvalidTargetBucket(address _farm, uint256 _maturity, uint256 _userUnbondingTimestamp);
    event FarmVoteRegistered(
        uint256 indexed timestamp,
        uint256 indexed epoch,
        address indexed user,
        uint32 unwindingEpochs,
        AllocationVote[] liquidVotes,
        AllocationVote[] illiquidVotes
    );
    struct AllocationVote {
        address farm;
        uint96 weight;
    }
    struct FarmWeightData {
        uint32 epoch;
        uint112 currentWeight;
        uint112 nextWeight;
    }
    address public lockingController;
    address public farmRegistry;
    mapping(address farm => FarmWeightData) public farmWeightData;
    mapping(address user => mapping(uint32 unwindingEpochs => uint32 epoch)) public lastVoteEpoch;
    constructor(address _core, address _lockingController, address _farmRegistry) CoreControlled(_core) {
        lockingController = _lockingController;
        farmRegistry = _farmRegistry;
    }
    function getVote(address _farm) external view returns (uint256) {
        return _getFarmWeight(farmWeightData[_farm], uint32(block.timestamp.epoch()));
    }
    function getVoteWeights(uint256 _farmType) external view returns (address[] memory, uint256[] memory, uint256) {
        address[] memory farms = FarmRegistry(farmRegistry).getTypeFarms(_farmType);
        (uint256[] memory weights, uint256 totalPower) = _getVoteWeights(farms);
        return (farms, weights, totalPower);
    }
    function getAssetVoteWeights(address _asset, uint256 _farmType)
        external
        view
        returns (address[] memory, uint256[] memory, uint256)
    {
        address[] memory farms = FarmRegistry(farmRegistry).getAssetTypeFarms(_asset, _farmType);
        (uint256[] memory weights, uint256 totalPower) = _getVoteWeights(farms);
        return (farms, weights, totalPower);
    }
    function vote(
        address _user,
        address _asset,
        uint32 _unwindingEpochs,
        AllocationVote[] calldata _liquidVotes,
        AllocationVote[] calldata _illiquidVotes
    ) external whenNotPaused onlyCoreRole(CoreRoles.ENTRY_POINT) {
        require(FarmRegistry(farmRegistry).isAssetEnabled(_asset), InvalidAsset(_asset));
        uint32 epoch = uint32(block.timestamp.epoch());
        require(lastVoteEpoch[_user][_unwindingEpochs] < epoch, AlreadyVoted(_user, _unwindingEpochs));
        lastVoteEpoch[_user][_unwindingEpochs] = epoch;
        uint256 weight = LockingController(lockingController).rewardWeightForUnwindingEpochs(_user, _unwindingEpochs);
        require(weight > 0, NoVotingPower(_user, _unwindingEpochs));
        if (_illiquidVotes.length > 0) {
            _storeUserVotes(_asset, _unwindingEpochs, epoch, weight, _illiquidVotes, false);
        }
        if (_liquidVotes.length > 0) {
            _storeUserVotes(_asset, _unwindingEpochs, epoch, weight, _liquidVotes, true);
        }
        address shareToken = LockingController(lockingController).shareToken(_unwindingEpochs);
        LockedPositionToken(shareToken).restrictTransferUntilNextEpoch(_user);
        emit FarmVoteRegistered(block.timestamp, epoch, _user, _unwindingEpochs, _liquidVotes, _illiquidVotes);
    }
    function _getFarmWeight(FarmWeightData memory _data, uint32 _epoch) internal pure returns (uint256) {
        if (_data.epoch == _epoch) {
            return _data.currentWeight;
        }
        if (_data.epoch == _epoch - 1) {
            return _data.nextWeight;
        }
        return 0;
    }
    function _storeUserVotes(
        address _asset,
        uint32 _unwindingEpochs,
        uint32 _epoch,
        uint256 _userWeight,
        AllocationVote[] calldata _votes,
        bool _liquid
    ) internal {
        uint256 weightAllocated = 0;
        for (uint256 i = 0; i < _votes.length; i++) {
            address farm = _votes[i].farm;
            if (_liquid) {
                _validateAssetAndType(_asset, farm, FarmTypes.LIQUID);
            } else {
                _validateAssetAndType(_asset, farm, FarmTypes.MATURITY);
                _validateFarmBucket(farm, _unwindingEpochs);
            }
            FarmWeightData memory data = farmWeightData[farm];
            if (data.epoch != _epoch) {
                if (data.epoch == _epoch - 1) {
                    data = FarmWeightData({epoch: _epoch, currentWeight: data.nextWeight, nextWeight: 0});
                } else {
                    data = FarmWeightData({epoch: _epoch, currentWeight: 0, nextWeight: 0});
                }
            }
            data.nextWeight += uint112(_userWeight.mulWadDown(_votes[i].weight));
            farmWeightData[farm] = data;
            weightAllocated += _votes[i].weight;
        }
        require(
            weightAllocated == FixedPointMathLib.WAD || weightAllocated == 0,
            InvalidWeights(FixedPointMathLib.WAD, weightAllocated)
        );
    }
    function _getVoteWeights(address[] memory _farms) internal view returns (uint256[] memory, uint256) {
        uint32 epoch = uint32(block.timestamp.epoch());
        uint256[] memory weights = new uint256[](_farms.length);
        uint256 totalPower = 0;
        for (uint256 i = 0; i < _farms.length; i++) {
            weights[i] = _getFarmWeight(farmWeightData[_farms[i]], epoch);
            totalPower += weights[i];
        }
        return (weights, totalPower);
    }
    function _validateAssetAndType(address _asset, address _farm, uint256 _type) internal view {
        FarmRegistry _farmRegistry = FarmRegistry(farmRegistry);
        require(_farmRegistry.isFarmOfType(_farm, uint256(_type)), UnknownFarm(_farm, true));
        require(_farmRegistry.isFarmOfAsset(_farm, _asset), InvalidAsset(_asset));
    }
    function _validateFarmBucket(address _farm, uint32 _unwindingEpochs) internal view {
        uint256 maturity = IMaturityFarm(_farm).maturity();
        uint256 userUnwindingTimestamp = (block.timestamp.nextEpoch() + _unwindingEpochs).epochToTimestamp();
        require(maturity <= userUnwindingTimestamp, InvalidTargetBucket(_farm, maturity, userUnwindingTimestamp));
    }
}
--- END FILE: ../infinify_certora_report/src/governance/AllocationVoting.sol ---
--- START FILE: ../infinify_certora_report/src/finance/YieldSharing.sol ---
pragma solidity 0.8.28;
import {FixedPointMathLib} from "@solmate/src/utils/FixedPointMathLib.sol";
import {CoreRoles} from "@libraries/CoreRoles.sol";
import {Accounting} from "@finance/Accounting.sol";
import {StakedToken} from "@tokens/StakedToken.sol";
import {ReceiptToken} from "@tokens/ReceiptToken.sol";
import {CoreControlled} from "@core/CoreControlled.sol";
import {LockingController} from "@locking/LockingController.sol";
import {FixedPriceOracle} from "@finance/oracles/FixedPriceOracle.sol";
contract YieldSharing is CoreControlled {
    using FixedPointMathLib for uint256;
    error PerformanceFeeTooHigh(uint256 _percent);
    error PerformanceFeeRecipientIsZeroAddress(address _recipient);
    error TargetIlliquidRatioTooHigh(uint256 _ratio);
    event YieldAccrued(uint256 indexed timestamp, int256 yield);
    event TargetIlliquidRatioUpdated(uint256 indexed timestamp, uint256 multiplier);
    event SafetyBufferSizeUpdated(uint256 indexed timestamp, uint256 value);
    event LiquidMultiplierUpdated(uint256 indexed timestamp, uint256 multiplier);
    event PerformanceFeeSettingsUpdated(uint256 indexed timestamp, uint256 percentage, address recipient);
    uint256 public constant MAX_PERFORMANCE_FEE = 0.2e18; 
    address public immutable accounting;
    address public immutable receiptToken;
    address public immutable stakedToken;
    address public immutable lockingModule;
    uint256 public safetyBufferSize;
    uint256 public performanceFee; 
    address public performanceFeeRecipient;
    uint256 public liquidReturnMultiplier = FixedPointMathLib.WAD; 
    uint256 public targetIlliquidRatio; 
    struct StakedReceiptTokenCache {
        uint48 blockTimestamp;
        uint208 amount;
    }
    StakedReceiptTokenCache public stakedReceiptTokenCache;
    constructor(address _core, address _accounting, address _receiptToken, address _stakedToken, address _lockingModule)
        CoreControlled(_core)
    {
        accounting = _accounting;
        receiptToken = _receiptToken;
        stakedToken = _stakedToken;
        lockingModule = _lockingModule;
        ReceiptToken(receiptToken).approve(_stakedToken, type(uint256).max);
        ReceiptToken(receiptToken).approve(_lockingModule, type(uint256).max);
    }
    function setSafetyBufferSize(uint256 _safetyBufferSize) external onlyCoreRole(CoreRoles.PROTOCOL_PARAMETERS) {
        safetyBufferSize = _safetyBufferSize;
        emit SafetyBufferSizeUpdated(block.timestamp, _safetyBufferSize);
    }
    function setPerformanceFeeAndRecipient(uint256 _percent, address _recipient)
        external
        onlyCoreRole(CoreRoles.PROTOCOL_PARAMETERS)
    {
        require(_percent <= MAX_PERFORMANCE_FEE, PerformanceFeeTooHigh(_percent));
        if (_percent > 0) {
            require(_recipient != address(0), PerformanceFeeRecipientIsZeroAddress(_recipient));
        }
        performanceFee = _percent;
        performanceFeeRecipient = _recipient;
        emit PerformanceFeeSettingsUpdated(block.timestamp, _percent, _recipient);
    }
    function setLiquidReturnMultiplier(uint256 _multiplier) external onlyCoreRole(CoreRoles.PROTOCOL_PARAMETERS) {
        liquidReturnMultiplier = _multiplier;
        emit LiquidMultiplierUpdated(block.timestamp, _multiplier);
    }
    function setTargetIlliquidRatio(uint256 _ratio) external onlyCoreRole(CoreRoles.PROTOCOL_PARAMETERS) {
        require(_ratio <= FixedPointMathLib.WAD, TargetIlliquidRatioTooHigh(_ratio));
        targetIlliquidRatio = _ratio;
        emit TargetIlliquidRatioUpdated(block.timestamp, _ratio);
    }
    function unaccruedYield() public view returns (int256) {
        uint256 receiptTokenPrice = Accounting(accounting).price(receiptToken);
        uint256 assets = Accounting(accounting).totalAssetsValue(); 
        uint256 assetsInReceiptTokens = assets.divWadDown(receiptTokenPrice);
        return int256(assetsInReceiptTokens) - int256(ReceiptToken(receiptToken).totalSupply());
    }
    function accrue() external whenNotPaused {
        int256 yield = unaccruedYield();
        if (yield > 0) _handlePositiveYield(uint256(yield));
        else if (yield < 0) _handleNegativeYield(uint256(-yield));
        emit YieldAccrued(block.timestamp, yield);
    }
    function getCachedStakedReceiptTokens() public returns (uint256) {
        StakedReceiptTokenCache memory data = stakedReceiptTokenCache;
        if (uint256(data.blockTimestamp) == block.timestamp) {
            return uint256(data.amount);
        }
        uint256 amount = ReceiptToken(receiptToken).balanceOf(stakedToken);
        assert(amount <= type(uint208).max);
        stakedReceiptTokenCache.blockTimestamp = uint48(block.timestamp);
        stakedReceiptTokenCache.amount = uint208(amount);
        return amount;
    }
    function _handlePositiveYield(uint256 _positiveYield) internal {
        uint256 stakedReceiptTokens = getCachedStakedReceiptTokens().mulWadDown(liquidReturnMultiplier);
        uint256 receiptTokenTotalSupply = ReceiptToken(receiptToken).totalSupply();
        uint256 targetIlliquidMinimum = receiptTokenTotalSupply.mulWadDown(targetIlliquidRatio);
        uint256 lockingReceiptTokens = LockingController(lockingModule).totalBalance();
        if (lockingReceiptTokens < targetIlliquidMinimum) {
            lockingReceiptTokens = targetIlliquidMinimum;
        }
        uint256 bondingMultiplier = LockingController(lockingModule).rewardMultiplier();
        lockingReceiptTokens = lockingReceiptTokens.mulWadDown(bondingMultiplier);
        uint256 totalReceiptTokens = stakedReceiptTokens + lockingReceiptTokens;
        ReceiptToken(receiptToken).mint(address(this), _positiveYield);
        uint256 _safetyBufferSize = safetyBufferSize;
        if (_safetyBufferSize > 0) {
            uint256 safetyBuffer = ReceiptToken(receiptToken).balanceOf(address(this)) - _positiveYield;
            if (safetyBuffer < _safetyBufferSize) {
                if (safetyBuffer + _positiveYield > _safetyBufferSize) {
                    _positiveYield -= _safetyBufferSize - safetyBuffer;
                } else {
                    return;
                }
            }
        }
        uint256 _performanceFee = performanceFee;
        if (_performanceFee > 0) {
            uint256 fee = _positiveYield.mulWadDown(_performanceFee);
            if (fee > 0) {
                ReceiptToken(receiptToken).transfer(performanceFeeRecipient, fee);
                _positiveYield -= fee;
            }
        }
        if (totalReceiptTokens == 0) {
            return;
        }
        uint256 stakingProfit = _positiveYield.mulDivDown(stakedReceiptTokens, totalReceiptTokens);
        if (stakingProfit > 0) {
            StakedToken(stakedToken).depositRewards(stakingProfit);
        }
        uint256 lockingProfit = _positiveYield - stakingProfit;
        if (lockingProfit > 0) {
            LockingController(lockingModule).depositRewards(lockingProfit);
        }
    }
    function _handleNegativeYield(uint256 _negativeYield) internal {
        uint256 safetyBuffer = ReceiptToken(receiptToken).balanceOf(address(this));
        if (safetyBuffer >= _negativeYield) {
            ReceiptToken(receiptToken).burn(_negativeYield);
            return;
        }
        uint256 lockingReceiptTokens = LockingController(lockingModule).totalBalance();
        if (_negativeYield <= lockingReceiptTokens) {
            LockingController(lockingModule).applyLosses(_negativeYield);
            return;
        }
        LockingController(lockingModule).applyLosses(lockingReceiptTokens);
        _negativeYield -= lockingReceiptTokens;
        uint256 stakedReceiptTokens = ReceiptToken(receiptToken).balanceOf(stakedToken);
        if (_negativeYield <= stakedReceiptTokens) {
            StakedToken(stakedToken).applyLosses(_negativeYield);
            return;
        }
        StakedToken(stakedToken).applyLosses(stakedReceiptTokens);
        _negativeYield -= stakedReceiptTokens;
        uint256 totalSupply = ReceiptToken(receiptToken).totalSupply();
        address oracle = Accounting(accounting).oracle(receiptToken);
        uint256 price = FixedPriceOracle(oracle).price();
        uint256 newPrice = price.mulDivDown(totalSupply - _negativeYield, totalSupply);
        FixedPriceOracle(oracle).setPrice(newPrice);
    }
}
--- END FILE: ../infinify_certora_report/src/finance/YieldSharing.sol ---
--- START FILE: ../infinify_certora_report/src/finance/Accounting.sol ---
pragma solidity 0.8.28;
import {FixedPointMathLib} from "@solmate/src/utils/FixedPointMathLib.sol";
import {IFarm} from "@interfaces/IFarm.sol";
import {IOracle} from "@interfaces/IOracle.sol";
import {CoreRoles} from "@libraries/CoreRoles.sol";
import {FarmRegistry} from "@integrations/FarmRegistry.sol";
import {CoreControlled} from "@core/CoreControlled.sol";
import {FixedPriceOracle} from "@finance/oracles/FixedPriceOracle.sol";
contract Accounting is CoreControlled {
    using FixedPointMathLib for uint256;
    event PriceSet(uint256 indexed timestamp, address indexed asset, uint256 price);
    event OracleSet(uint256 indexed timestamp, address indexed asset, address oracle);
    address public immutable farmRegistry;
    constructor(address _core, address _farmRegistry) CoreControlled(_core) {
        farmRegistry = _farmRegistry;
    }
    mapping(address => address) public oracle;
    function price(address _asset) external view returns (uint256) {
        return IOracle(oracle[_asset]).price();
    }
    function setOracle(address _asset, address _oracle) external onlyCoreRole(CoreRoles.ORACLE_MANAGER) {
        oracle[_asset] = _oracle;
        emit OracleSet(block.timestamp, _asset, _oracle);
    }
    function totalAssetsValue() external view returns (uint256 _totalValue) {
        address[] memory assets = FarmRegistry(farmRegistry).getEnabledAssets();
        for (uint256 i = 0; i < assets.length; i++) {
            uint256 assetPrice = IOracle(oracle[assets[i]]).price();
            uint256 _assets = _calculateTotalAssets(FarmRegistry(farmRegistry).getAssetFarms(assets[i]));
            _totalValue += _assets.mulWadDown(assetPrice);
        }
    }
    function totalAssetsValueOf(uint256 _type) external view returns (uint256 _totalValue) {
        address[] memory assets = FarmRegistry(farmRegistry).getEnabledAssets();
        for (uint256 i = 0; i < assets.length; i++) {
            uint256 assetPrice = IOracle(oracle[assets[i]]).price();
            address[] memory assetFarms = FarmRegistry(farmRegistry).getAssetTypeFarms(assets[i], uint256(_type));
            uint256 _assets = _calculateTotalAssets(assetFarms);
            _totalValue += _assets.mulWadDown(assetPrice);
        }
    }
    function totalAssets(address _asset) external view returns (uint256) {
        return _calculateTotalAssets(FarmRegistry(farmRegistry).getAssetFarms(_asset));
    }
    function totalAssetsOf(address _asset, uint256 _type) external view returns (uint256) {
        return _calculateTotalAssets(FarmRegistry(farmRegistry).getAssetTypeFarms(_asset, uint256(_type)));
    }
    function _calculateTotalAssets(address[] memory _farms) internal view returns (uint256 _totalAssets) {
        uint256 length = _farms.length;
        for (uint256 index = 0; index < length; index++) {
            _totalAssets += IFarm(_farms[index]).assets();
        }
    }
}
--- END FILE: ../infinify_certora_report/src/finance/Accounting.sol ---
--- START FILE: ../infinify_certora_report/src/finance/oracles/FixedPriceOracle.sol ---
pragma solidity 0.8.28;
import {IOracle} from "@interfaces/IOracle.sol";
import {CoreControlled, CoreRoles} from "@core/CoreControlled.sol";
contract FixedPriceOracle is IOracle, CoreControlled {
    uint256 public price;
    event PriceSet(uint256 indexed timestamp, uint256 price);
    constructor(address _core, uint256 _price) CoreControlled(_core) {
        price = _price;
    }
    function setPrice(uint256 _price) external onlyCoreRole(CoreRoles.ORACLE_MANAGER) {
        price = _price;
        emit PriceSet(block.timestamp, _price);
    }
}
--- END FILE: ../infinify_certora_report/src/finance/oracles/FixedPriceOracle.sol ---
--- START FILE: ../infinify_certora_report/src/funding/RedemptionPool.sol ---
pragma solidity 0.8.28;
import {RedemptionQueue} from "@libraries/RedemptionQueue.sol";
import {FixedPointMathLib} from "@solmate/src/utils/FixedPointMathLib.sol";
abstract contract RedemptionPool {
    using RedemptionQueue for RedemptionQueue.RedemptionRequestsQueue;
    using FixedPointMathLib for uint256;
    error FundingAmountZero();
    error EnqueueAmountZero();
    error NoPendingClaims(address _recipient);
    error QueueTooLong();
    error EnqueueAmountTooLarge();
    event RedemptionQueued(uint256 indexed timestamp, address recipient, uint256 amount);
    event RedemptionPartiallyFunded(uint256 indexed timestamp, address recipient, uint256 amount);
    event RedemptionFunded(uint256 indexed timestamp, address recipient, uint256 amount);
    event RedemptionClaimed(uint256 indexed timestamp, address recipient, uint256 amount);
    RedemptionQueue.RedemptionRequestsQueue public queue;
    uint256 public constant MAX_QUEUE_LENGTH = 10000;
    mapping(address recipient => uint256 assetAmount) public userPendingClaims;
    uint256 public totalPendingClaims;
    uint256 public totalEnqueuedRedemptions;
    function queueLength() public view returns (uint256) {
        return queue.length();
    }
    function _fundRedemptionQueue(uint256 _assetAmount, uint256 _convertReceiptToAssetRatio)
        internal
        returns (uint256, uint256)
    {
        require(_assetAmount > 0, FundingAmountZero());
        uint256 totalEnqueuedRedemptionsBefore = totalEnqueuedRedemptions; 
        uint256 remainingAssets = _assetAmount; 
        uint256 _totalPendingClaims = totalPendingClaims;
        uint256 _totalEnqueuedRedemptions = totalEnqueuedRedemptions;
        while (remainingAssets > 0 && !queue.empty()) {
            RedemptionQueue.RedemptionRequest memory request = queue.front();
            uint256 assetRequired = uint256(request.amount).mulWadDown(_convertReceiptToAssetRatio); 
            uint256 receiptToBurn = request.amount; 
            if (assetRequired > remainingAssets) {
                assetRequired = remainingAssets;
                receiptToBurn = remainingAssets.divWadUp(_convertReceiptToAssetRatio); 
                uint96 newReceiptAmount = request.amount - uint96(receiptToBurn); 
                queue.updateFront(newReceiptAmount); 
                emit RedemptionPartiallyFunded(block.timestamp, request.recipient, remainingAssets); 
            } else {
                queue.popFront();
                emit RedemptionFunded(block.timestamp, request.recipient, assetRequired); 
            }
            userPendingClaims[request.recipient] += assetRequired; 
            remainingAssets -= assetRequired; 
            _totalPendingClaims += assetRequired; 
            _totalEnqueuedRedemptions -= receiptToBurn; 
        }
        totalPendingClaims = _totalPendingClaims; 
        totalEnqueuedRedemptions = _totalEnqueuedRedemptions; 
        uint256 receiptAmountToBurn = totalEnqueuedRedemptionsBefore - totalEnqueuedRedemptions; 
        return (remainingAssets, receiptAmountToBurn); 
    }
    function _claimRedemption(address _recipient) internal returns (uint256) {
        uint256 amount = userPendingClaims[_recipient];
        require(amount > 0, NoPendingClaims(_recipient));
        userPendingClaims[_recipient] = 0;
        totalPendingClaims -= amount;
        emit RedemptionClaimed(block.timestamp, _recipient, amount);
        return amount;
    }
    function _enqueue(address _recipient, uint256 _amount) internal {
        require(queue.length() < MAX_QUEUE_LENGTH, QueueTooLong());
        require(_amount > 0, EnqueueAmountZero());
        require(_amount <= type(uint96).max, EnqueueAmountTooLarge());
        totalEnqueuedRedemptions += _amount;
        queue.pushBack(RedemptionQueue.RedemptionRequest({amount: uint96(_amount), recipient: _recipient}));
        emit RedemptionQueued(block.timestamp, _recipient, _amount);
    }
}
--- END FILE: ../infinify_certora_report/src/funding/RedemptionPool.sol ---
--- START FILE: ../infinify_certora_report/src/funding/MintController.sol ---
pragma solidity 0.8.28;
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {FixedPointMathLib} from "@solmate/src/utils/FixedPointMathLib.sol";
import {Farm} from "@integrations/Farm.sol";
import {CoreRoles} from "@libraries/CoreRoles.sol";
import {Accounting} from "@finance/Accounting.sol";
import {ReceiptToken} from "@tokens/ReceiptToken.sol";
import {IMintController, IAfterMintHook} from "@interfaces/IMintController.sol";
contract MintController is Farm, IMintController {
    using SafeERC20 for ERC20;
    using FixedPointMathLib for uint256;
    address public immutable receiptToken;
    address public immutable accounting;
    uint256 public minAssetAmount = 1;
    address public afterMintHook;
    constructor(address _core, address _assetToken, address _receiptToken, address _accounting)
        Farm(_core, _assetToken)
    {
        receiptToken = _receiptToken;
        accounting = _accounting;
    }
    function setMinAssetAmount(uint256 _minAssetAmount) external onlyCoreRole(CoreRoles.PROTOCOL_PARAMETERS) {
        require(_minAssetAmount > 0, AssetAmountTooLow(_minAssetAmount, 1));
        minAssetAmount = _minAssetAmount;
        emit MinAssetAmountUpdated(block.timestamp, _minAssetAmount);
    }
    function setAfterMintHook(address _afterMintHook) external onlyCoreRole(CoreRoles.GOVERNOR) {
        afterMintHook = _afterMintHook;
        emit AfterMintHookChanged(block.timestamp, _afterMintHook);
    }
    function assetToReceipt(uint256 _assetAmount) public view returns (uint256) {
        uint256 assetTokenPrice = Accounting(accounting).price(assetToken);
        uint256 receiptTokenPrice = Accounting(accounting).price(receiptToken);
        uint256 convertRatio = receiptTokenPrice.divWadUp(assetTokenPrice);
        return _assetAmount.divWadDown(convertRatio);
    }
    function assets() public view override returns (uint256) {
        return ERC20(assetToken).balanceOf(address(this));
    }
    function liquidity() public view override returns (uint256) {
        return ERC20(assetToken).balanceOf(address(this));
    }
    function mint(address _to, uint256 _assetAmountIn)
        external
        whenNotPaused
        onlyCoreRole(CoreRoles.ENTRY_POINT)
        returns (uint256)
    {
        require(_assetAmountIn >= minAssetAmount, AssetAmountTooLow(_assetAmountIn, minAssetAmount));
        uint256 receiptAmountOut = assetToReceipt(_assetAmountIn);
        ERC20(assetToken).safeTransferFrom(msg.sender, address(this), _assetAmountIn);
        ReceiptToken(receiptToken).mint(_to, receiptAmountOut);
        address _afterMintHook = afterMintHook;
        if (_afterMintHook != address(0)) {
            IAfterMintHook(_afterMintHook).afterMint(_to, _assetAmountIn);
        }
        emit Mint(block.timestamp, _to, assetToken, _assetAmountIn, receiptAmountOut);
        return receiptAmountOut;
    }
    function _deposit(uint256) internal override {} 
    function deposit() external override onlyCoreRole(CoreRoles.FARM_MANAGER) whenNotPaused {
        _deposit(0);
    }
    function _withdraw(uint256 _amount, address _to) internal override {
        ERC20(assetToken).safeTransfer(_to, _amount);
    }
    function withdraw(uint256 amount, address to)
        external
        override
        onlyCoreRole(CoreRoles.FARM_MANAGER)
        whenNotPaused
    {
        _withdraw(amount, to);
    }
}
--- END FILE: ../infinify_certora_report/src/funding/MintController.sol ---
--- START FILE: ../infinify_certora_report/src/funding/RedeemController.sol ---
pragma solidity 0.8.28;
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {FixedPointMathLib} from "@solmate/src/utils/FixedPointMathLib.sol";
import {Farm} from "@integrations/Farm.sol";
import {CoreRoles} from "@libraries/CoreRoles.sol";
import {Accounting} from "@finance/Accounting.sol";
import {ReceiptToken} from "@tokens/ReceiptToken.sol";
import {RedemptionPool} from "@funding/RedemptionPool.sol";
import {IRedeemController, IBeforeRedeemHook} from "@interfaces/IRedeemController.sol";
contract RedeemController is Farm, RedemptionPool, IRedeemController {
    using SafeERC20 for ERC20;
    using FixedPointMathLib for uint256;
    address public immutable receiptToken;
    address public immutable accounting;
    uint256 public minRedemptionAmount = 1;
    address public beforeRedeemHook;
    constructor(address _core, address _assetToken, address _receiptToken, address _accounting)
        Farm(_core, _assetToken)
    {
        receiptToken = _receiptToken;
        accounting = _accounting;
    }
    function setMinRedemptionAmount(uint256 _minRedemptionAmount)
        external
        onlyCoreRole(CoreRoles.PROTOCOL_PARAMETERS)
    {
        require(_minRedemptionAmount > 0, RedeemAmountTooLow(_minRedemptionAmount, 1));
        minRedemptionAmount = _minRedemptionAmount;
        emit MinRedemptionAmountUpdated(block.timestamp, _minRedemptionAmount);
    }
    function setBeforeRedeemHook(address _beforeRedeemHook) external onlyCoreRole(CoreRoles.GOVERNOR) {
        beforeRedeemHook = _beforeRedeemHook;
        emit BeforeRedeemHookChanged(block.timestamp, _beforeRedeemHook);
    }
    function receiptToAsset(uint256 _receiptAmount) external view returns (uint256) {
        uint256 convertRatio = _getReceiptToAssetConvertRatio();
        return _convertReceiptToAsset(_receiptAmount, convertRatio);
    }
    function assets() public view override returns (uint256) {
        uint256 assetTokenBalance = ERC20(assetToken).balanceOf(address(this));
        return assetTokenBalance - totalPendingClaims;
    }
    function liquidity() public view override returns (uint256) {
        return assets();
    }
    function redeem(address _to, uint256 _receiptAmountIn)
        external
        whenNotPaused
        onlyCoreRole(CoreRoles.ENTRY_POINT)
        returns (uint256)
    {
        require(_receiptAmountIn >= minRedemptionAmount, RedeemAmountTooLow(_receiptAmountIn, minRedemptionAmount));
        uint256 convertRatio = _getReceiptToAssetConvertRatio();
        uint256 assetAmountOut = _convertReceiptToAsset(_receiptAmountIn, convertRatio);
        if (queueLength() > 0) {
            uint256 _amountReceiptToQueue = _convertAssetToReceipt(assetAmountOut, convertRatio);
            ReceiptToken(receiptToken).transferFrom(msg.sender, address(this), _amountReceiptToQueue);
            _enqueue(_to, _amountReceiptToQueue);
            emit Redeem(block.timestamp, _to, assetToken, _receiptAmountIn, assetAmountOut);
            return 0;
        }
        address _beforeRedeemHook = beforeRedeemHook;
        if (_beforeRedeemHook != address(0)) {
            IBeforeRedeemHook(_beforeRedeemHook).beforeRedeem(_to, _receiptAmountIn, assetAmountOut);
        }
        uint256 availableAssetAmount = liquidity();
        if (assetAmountOut <= availableAssetAmount) {
            ReceiptToken(receiptToken).burnFrom(msg.sender, _receiptAmountIn);
            ERC20(assetToken).safeTransfer(_to, assetAmountOut);
            emit Redeem(block.timestamp, _to, assetToken, _receiptAmountIn, assetAmountOut);
            return assetAmountOut;
        } else {
            uint256 amountReceiptToBurn = _convertAssetToReceipt(availableAssetAmount, convertRatio);
            ReceiptToken(receiptToken).burnFrom(msg.sender, amountReceiptToBurn);
            ERC20(assetToken).safeTransfer(_to, availableAssetAmount);
            uint256 remainingReceiptToQueue = _receiptAmountIn - amountReceiptToBurn;
            ReceiptToken(receiptToken).transferFrom(msg.sender, address(this), remainingReceiptToQueue);
            _enqueue(_to, remainingReceiptToQueue);
            emit Redeem(block.timestamp, _to, assetToken, amountReceiptToBurn, availableAssetAmount);
            return availableAssetAmount;
        }
    }
    function claimRedemption(address _recipient) external whenNotPaused onlyCoreRole(CoreRoles.ENTRY_POINT) {
        uint256 assetsToSend = _claimRedemption(_recipient);
        ERC20(assetToken).safeTransfer(_recipient, assetsToSend);
    }
    function _deposit(uint256 assetsToDeposit) internal override {
        if (assetsToDeposit > 0) {
            (, uint256 receiptAmountToBurn) = _fundRedemptionQueue(assetsToDeposit, _getReceiptToAssetConvertRatio());
            if (receiptAmountToBurn > 0) {
                ReceiptToken(receiptToken).burn(receiptAmountToBurn);
            }
        }
    }
    function deposit() external override onlyCoreRole(CoreRoles.FARM_MANAGER) whenNotPaused {
        _deposit(liquidity());
    }
    function _withdraw(uint256 _amount, address _to) internal override {
        ERC20(assetToken).safeTransfer(_to, _amount);
    }
    function withdraw(uint256 amount, address to)
        external
        override
        onlyCoreRole(CoreRoles.FARM_MANAGER)
        whenNotPaused
    {
        _withdraw(amount, to);
    }
    function _getReceiptToAssetConvertRatio() internal view returns (uint256) {
        uint256 _assetTokenPrice = Accounting(accounting).price(assetToken);
        uint256 _receiptTokenPrice = Accounting(accounting).price(receiptToken);
        return _receiptTokenPrice.divWadUp(_assetTokenPrice);
    }
    function _convertReceiptToAsset(uint256 _amountReceipt, uint256 _convertRatio) internal pure returns (uint256) {
        return _amountReceipt.mulWadDown(_convertRatio);
    }
    function _convertAssetToReceipt(uint256 _amountAsset, uint256 _convertRatio) internal pure returns (uint256) {
        return _amountAsset.divWadUp(_convertRatio);
    }
}
--- END FILE: ../infinify_certora_report/src/funding/RedeemController.sol ---
--- START FILE: ../infinify_certora_report/src/integrations/FarmRegistry.sol ---
pragma solidity 0.8.28;
import {IFarm} from "@interfaces/IFarm.sol";
import {CoreRoles} from "@libraries/CoreRoles.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {CoreControlled} from "@core/CoreControlled.sol";
contract FarmRegistry is CoreControlled {
    error FarmAlreadyAdded(address farm);
    error FarmNotFound(address farm);
    error AssetNotEnabled(address farm, address asset);
    error AssetAlreadyEnabled(address asset);
    error AssetNotFound(address asset);
    event AssetEnabled(uint256 indexed timestamp, address asset);
    event AssetDisabled(uint256 indexed timestamp, address asset);
    event FarmsAdded(uint256 indexed timestamp, uint256 farmType, address[] indexed farms);
    event FarmsRemoved(uint256 indexed timestamp, uint256 farmType, address[] indexed farms);
    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private assets;
    EnumerableSet.AddressSet private farms;
    mapping(uint256 _type => EnumerableSet.AddressSet _farms) private typeFarms;
    mapping(address _asset => EnumerableSet.AddressSet _farms) private assetFarms;
    mapping(address _asset => mapping(uint256 _type => EnumerableSet.AddressSet _farms)) private assetTypeFarms;
    constructor(address _core) CoreControlled(_core) {}
    function getEnabledAssets() external view returns (address[] memory) {
        return assets.values();
    }
    function isAssetEnabled(address _asset) external view returns (bool) {
        return assets.contains(_asset);
    }
    function getFarms() external view returns (address[] memory) {
        return farms.values();
    }
    function getTypeFarms(uint256 _type) external view returns (address[] memory) {
        return typeFarms[_type].values();
    }
    function getAssetFarms(address _asset) external view returns (address[] memory) {
        return assetFarms[_asset].values();
    }
    function getAssetTypeFarms(address _asset, uint256 _type) external view returns (address[] memory) {
        return assetTypeFarms[_asset][_type].values();
    }
    function isFarm(address _farm) external view returns (bool) {
        return farms.contains(_farm);
    }
    function isFarmOfAsset(address _farm, address _asset) external view returns (bool) {
        return assetFarms[_asset].contains(_farm);
    }
    function isFarmOfType(address _farm, uint256 _type) external view returns (bool) {
        return typeFarms[_type].contains(_farm);
    }
    function enableAsset(address _asset) external onlyCoreRole(CoreRoles.GOVERNOR) {
        require(assets.add(_asset), AssetAlreadyEnabled(_asset));
        emit AssetEnabled(block.timestamp, _asset);
    }
    function disableAsset(address _asset) external onlyCoreRole(CoreRoles.GOVERNOR) {
        require(assets.remove(_asset), AssetNotFound(_asset));
        emit AssetDisabled(block.timestamp, _asset);
    }
    function addFarms(uint256 _type, address[] calldata _list) external onlyCoreRole(CoreRoles.PROTOCOL_PARAMETERS) {
        _addFarms(_type, _list);
        emit FarmsAdded(block.timestamp, _type, _list);
    }
    function removeFarms(uint256 _type, address[] calldata _list)
        external
        onlyCoreRole(CoreRoles.PROTOCOL_PARAMETERS)
    {
        _removeFarms(_type, _list);
        emit FarmsRemoved(block.timestamp, _type, _list);
    }
    function _addFarms(uint256 _type, address[] calldata _list) internal {
        for (uint256 i = 0; i < _list.length; i++) {
            address farmAsset = IFarm(_list[i]).assetToken();
            require(assets.contains(farmAsset), AssetNotEnabled(_list[i], farmAsset));
            require(farms.add(_list[i]), FarmAlreadyAdded(_list[i]));
            require(typeFarms[_type].add(_list[i]), FarmAlreadyAdded(_list[i]));
            require(assetFarms[farmAsset].add(_list[i]), FarmAlreadyAdded(_list[i]));
            require(assetTypeFarms[farmAsset][_type].add(_list[i]), FarmAlreadyAdded(_list[i]));
        }
    }
    function _removeFarms(uint256 _type, address[] calldata _list) internal {
        for (uint256 i = 0; i < _list.length; i++) {
            address farmAsset = IFarm(_list[i]).assetToken();
            require(farms.remove(_list[i]), FarmNotFound(_list[i]));
            require(typeFarms[_type].remove(_list[i]), FarmNotFound(_list[i]));
            require(assetFarms[farmAsset].remove(_list[i]), FarmNotFound(_list[i]));
            require(assetTypeFarms[farmAsset][_type].remove(_list[i]), FarmNotFound(_list[i]));
        }
    }
}
--- END FILE: ../infinify_certora_report/src/integrations/FarmRegistry.sol ---
--- START FILE: ../infinify_certora_report/src/integrations/Farm.sol ---
pragma solidity 0.8.28;
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {FixedPointMathLib} from "@solmate/src/utils/FixedPointMathLib.sol";
import {IFarm} from "@interfaces/IFarm.sol";
import {CoreRoles} from "@libraries/CoreRoles.sol";
import {CoreControlled} from "@core/CoreControlled.sol";
abstract contract Farm is CoreControlled, IFarm {
    using FixedPointMathLib for uint256;
    address public immutable assetToken;
    uint256 public cap;
    uint256 public maxSlippage;
    error CapExceeded(uint256 newAmount, uint256 cap);
    error SlippageTooHigh(uint256 minAssetsOut, uint256 assetsReceived);
    event CapUpdated(uint256 newCap);
    event MaxSlippageUpdated(uint256 newMaxSlippage);
    constructor(address _core, address _assetToken) CoreControlled(_core) {
        assetToken = _assetToken;
        cap = type(uint256).max;
        maxSlippage = 0.999999e18;
    }
    function setCap(uint256 _newCap) external onlyCoreRole(CoreRoles.PROTOCOL_PARAMETERS) {
        cap = _newCap;
        emit CapUpdated(_newCap);
    }
    function setMaxSlippage(uint256 _maxSlippage) external onlyCoreRole(CoreRoles.PROTOCOL_PARAMETERS) {
        maxSlippage = _maxSlippage;
        emit MaxSlippageUpdated(_maxSlippage);
    }
    function assets() public view virtual returns (uint256);
    function maxDeposit() external view virtual returns (uint256) {
        uint256 currentAssets = assets();
        if (currentAssets >= cap) {
            return 0;
        }
        return cap - currentAssets;
    }
    function deposit() external virtual onlyCoreRole(CoreRoles.FARM_MANAGER) whenNotPaused {
        uint256 assetsToDeposit = ERC20(assetToken).balanceOf(address(this));
        uint256 assetsBefore = assets();
        if (assetsBefore + assetsToDeposit > cap) {
            revert CapExceeded(assetsBefore + assetsToDeposit, cap);
        }
        _deposit(assetsToDeposit);
        uint256 assetsAfter = assets();
        uint256 assetsReceived = assetsAfter - assetsBefore;
        uint256 minAssetsOut = assetsToDeposit.mulWadDown(maxSlippage);
        require(assetsReceived >= minAssetsOut, SlippageTooHigh(minAssetsOut, assetsReceived));
        emit AssetsUpdated(block.timestamp, assetsBefore, assetsAfter);
    }
    function _deposit(uint256 assetsToDeposit) internal virtual;
    function withdraw(uint256 amount, address to) external virtual onlyCoreRole(CoreRoles.FARM_MANAGER) whenNotPaused {
        uint256 assetsBefore = assets();
        _withdraw(amount, to);
        uint256 assetsAfter = assets();
        uint256 assetsSpent = assetsBefore - assetsAfter;
        uint256 minAssetsOut = assetsSpent.mulWadDown(maxSlippage);
        require(amount >= minAssetsOut, SlippageTooHigh(minAssetsOut, amount));
        emit AssetsUpdated(block.timestamp, assetsBefore, assetsAfter);
    }
    function _withdraw(uint256, address) internal virtual;
}
--- END FILE: ../infinify_certora_report/src/integrations/Farm.sol ---
--- START FILE: ../infinify_certora_report/src/gateway/InfiniFiGatewayV1.sol ---
pragma solidity 0.8.28;
import {FixedPointMathLib} from "@solmate/src/utils/FixedPointMathLib.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {CoreRoles} from "@libraries/CoreRoles.sol";
import {StakedToken} from "@tokens/StakedToken.sol";
import {ReceiptToken} from "@tokens/ReceiptToken.sol";
import {CoreControlled} from "@core/CoreControlled.sol";
import {MintController} from "@funding/MintController.sol";
import {RedeemController} from "@funding/RedeemController.sol";
import {AllocationVoting} from "@governance/AllocationVoting.sol";
import {LockingController} from "@locking/LockingController.sol";
import {LockedPositionToken} from "@tokens/LockedPositionToken.sol";
import {YieldSharing} from "@finance/YieldSharing.sol";
contract InfiniFiGatewayV1 is CoreControlled {
    using SafeERC20 for ERC20;
    using FixedPointMathLib for uint256;
    error PendingLossesUnapplied();
    error SwapFailed();
    error InvalidZapFee();
    event AddressSet(uint256 timestamp, string indexed name, address _address);
    event ZapFeeSet(uint256 timestamp, uint256 zapFee);
    event ZapIn(uint256 timestamp, address indexed user, address indexed token, uint256 amount, uint256 receiptTokens);
    mapping(bytes32 => address) public addresses;
    uint256 public zapFee;
    constructor() CoreControlled(address(1)) {}
    function init(address _core) external {
        assert(address(core()) == address(0));
        _setCore(_core);
    }
    function setAddress(string memory _name, address _address) external onlyCoreRole(CoreRoles.GOVERNOR) {
        addresses[keccak256(abi.encode(_name))] = _address;
        emit AddressSet(block.timestamp, _name, _address);
    }
    function getAddress(string memory _name) public view returns (address) {
        return addresses[keccak256(abi.encode(_name))];
    }
    function setZapFee(uint256 _zapFee) external onlyCoreRole(CoreRoles.PROTOCOL_PARAMETERS) {
        require(_zapFee <= 0.01e18, InvalidZapFee()); 
        zapFee = _zapFee;
        emit ZapFeeSet(block.timestamp, _zapFee);
    }
    function mint(address _to, uint256 _amount) external whenNotPaused returns (uint256) {
        ERC20 usdc = ERC20(getAddress("USDC"));
        MintController mintController = MintController(getAddress("mintController"));
        usdc.safeTransferFrom(msg.sender, address(this), _amount);
        usdc.approve(address(mintController), _amount);
        return mintController.mint(_to, _amount);
    }
    function mintAndStake(address _to, uint256 _amount) external whenNotPaused returns (uint256) {
        MintController mintController = MintController(getAddress("mintController"));
        StakedToken siusd = StakedToken(getAddress("stakedToken"));
        ReceiptToken iusd = ReceiptToken(getAddress("receiptToken"));
        ERC20 usdc = ERC20(getAddress("USDC"));
        usdc.safeTransferFrom(msg.sender, address(this), _amount);
        usdc.approve(address(mintController), _amount);
        uint256 receiptTokens = mintController.mint(address(this), _amount);
        iusd.approve(address(siusd), receiptTokens);
        siusd.deposit(receiptTokens, _to);
        return receiptTokens;
    }
    function _zapToReceiptTokens(address _token, uint256 _amount, bytes calldata _routerData)
        internal
        returns (uint256, ReceiptToken)
    {
        address _router = getAddress("zapRouter");
        if (_token != address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)) {
            ERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
            ERC20(_token).forceApprove(address(_router), _amount);
        }
        (bool swapSuccess,) = _router.call{value: msg.value}(_routerData);
        require(swapSuccess, SwapFailed());
        MintController mintController = MintController(getAddress("mintController"));
        ERC20 usdc = ERC20(getAddress("USDC"));
        ReceiptToken iusd = ReceiptToken(getAddress("receiptToken"));
        uint256 usdcReceived = usdc.balanceOf(address(this));
        usdc.approve(address(mintController), usdcReceived);
        uint256 receiptTokens = mintController.mint(address(this), usdcReceived);
        {
            uint256 _zapFee = zapFee;
            if (_zapFee != 0) {
                uint256 fee = receiptTokens.mulWadDown(_zapFee);
                receiptTokens -= fee;
                iusd.transfer(getAddress("yieldSharing"), fee);
            }
        }
        emit ZapIn(block.timestamp, msg.sender, _token, _amount, receiptTokens);
        return (receiptTokens, iusd);
    }
    function zapIn(address _token, uint256 _amount, bytes calldata _routerData, address _to)
        external
        payable
        whenNotPaused
        returns (uint256)
    {
        (uint256 receiptTokens, ReceiptToken iusd) = _zapToReceiptTokens(_token, _amount, _routerData);
        iusd.transfer(_to, receiptTokens);
        return receiptTokens;
    }
    function zapInAndStake(address _token, uint256 _amount, bytes calldata _routerData, address _to)
        external
        payable
        whenNotPaused
        returns (uint256)
    {
        (uint256 receiptTokens, ReceiptToken iusd) = _zapToReceiptTokens(_token, _amount, _routerData);
        StakedToken siusd = StakedToken(getAddress("stakedToken"));
        iusd.approve(address(siusd), receiptTokens);
        siusd.deposit(receiptTokens, _to);
        return receiptTokens;
    }
    function zapInAndLock(
        address _token,
        uint256 _amount,
        bytes calldata _routerData,
        uint32 _unwindingEpochs,
        address _to
    ) external payable whenNotPaused returns (uint256) {
        (uint256 receiptTokens, ReceiptToken iusd) = _zapToReceiptTokens(_token, _amount, _routerData);
        LockingController lockingController = LockingController(getAddress("lockingController"));
        iusd.approve(address(lockingController), receiptTokens);
        lockingController.createPosition(receiptTokens, _unwindingEpochs, _to);
        return receiptTokens;
    }
    function mintAndLock(address _to, uint256 _amount, uint32 _unwindingEpochs)
        external
        whenNotPaused
        returns (uint256)
    {
        MintController mintController = MintController(getAddress("mintController"));
        ReceiptToken iusd = ReceiptToken(getAddress("receiptToken"));
        LockingController lockingController = LockingController(getAddress("lockingController"));
        ERC20 usdc = ERC20(getAddress("USDC"));
        usdc.safeTransferFrom(msg.sender, address(this), _amount);
        usdc.approve(address(mintController), _amount);
        uint256 receiptTokens = mintController.mint(address(this), _amount);
        iusd.approve(address(lockingController), receiptTokens);
        lockingController.createPosition(receiptTokens, _unwindingEpochs, _to);
        return receiptTokens;
    }
    function unstakeAndLock(address _to, uint256 _amount, uint32 _unwindingEpochs)
        external
        whenNotPaused
        returns (uint256)
    {
        ReceiptToken iusd = ReceiptToken(getAddress("receiptToken"));
        StakedToken siusd = StakedToken(getAddress("stakedToken"));
        LockingController lockingController = LockingController(getAddress("lockingController"));
        siusd.transferFrom(msg.sender, address(this), _amount);
        uint256 receiptTokens = siusd.redeem(_amount, address(this), address(this));
        iusd.approve(address(lockingController), receiptTokens);
        lockingController.createPosition(receiptTokens, _unwindingEpochs, _to);
        return receiptTokens;
    }
    function createPosition(uint256 _amount, uint32 _unwindingEpochs, address _recipient) external whenNotPaused {
        ReceiptToken iusd = ReceiptToken(getAddress("receiptToken"));
        LockingController lockingController = LockingController(getAddress("lockingController"));
        iusd.transferFrom(msg.sender, address(this), _amount);
        iusd.approve(address(lockingController), _amount);
        lockingController.createPosition(_amount, _unwindingEpochs, _recipient);
    }
    function startUnwinding(uint256 _shares, uint32 _unwindingEpochs) external whenNotPaused {
        LockingController lockingController = LockingController(getAddress("lockingController"));
        LockedPositionToken liusd = LockedPositionToken(lockingController.shareToken(_unwindingEpochs));
        liusd.transferFrom(msg.sender, address(this), _shares);
        liusd.approve(address(lockingController), _shares);
        lockingController.startUnwinding(_shares, _unwindingEpochs, msg.sender);
    }
    function increaseUnwindingEpochs(uint32 _oldUnwindingEpochs, uint32 _newUnwindingEpochs, uint256 _shares)
        external
        whenNotPaused
    {
        LockingController lockingController = LockingController(getAddress("lockingController"));
        LockedPositionToken liusd = LockedPositionToken(lockingController.shareToken(_oldUnwindingEpochs));
        liusd.transferFrom(msg.sender, address(this), _shares);
        liusd.approve(address(lockingController), _shares);
        lockingController.increaseUnwindingEpochs(_shares, _oldUnwindingEpochs, _newUnwindingEpochs, msg.sender);
    }
    function cancelUnwinding(uint256 _unwindingTimestamp, uint32 _newUnwindingEpochs) external whenNotPaused {
        LockingController(getAddress("lockingController")).cancelUnwinding(
            msg.sender, _unwindingTimestamp, _newUnwindingEpochs
        );
    }
    function withdraw(uint256 _unwindingTimestamp) external whenNotPaused {
        _revertIfThereAreUnaccruedLosses();
        LockingController(getAddress("lockingController")).withdraw(msg.sender, _unwindingTimestamp);
    }
    function redeem(address _to, uint256 _amount) external whenNotPaused returns (uint256) {
        _revertIfThereAreUnaccruedLosses();
        ReceiptToken iusd = ReceiptToken(getAddress("receiptToken"));
        RedeemController redeemController = RedeemController(getAddress("redeemController"));
        iusd.transferFrom(msg.sender, address(this), _amount);
        iusd.approve(address(redeemController), _amount);
        return redeemController.redeem(_to, _amount);
    }
    function claimRedemption() external whenNotPaused {
        RedeemController(getAddress("redeemController")).claimRedemption(msg.sender);
    }
    function vote(
        address _asset,
        uint32 _unwindingEpochs,
        AllocationVoting.AllocationVote[] calldata _liquidVotes,
        AllocationVoting.AllocationVote[] calldata _illiquidVotes
    ) external whenNotPaused {
        AllocationVoting(getAddress("allocationVoting")).vote(
            msg.sender, _asset, _unwindingEpochs, _liquidVotes, _illiquidVotes
        );
    }
    function multiVote(
        address[] calldata _assets,
        uint32[] calldata _unwindingEpochs,
        AllocationVoting.AllocationVote[][] calldata _liquidVotes,
        AllocationVoting.AllocationVote[][] calldata _illiquidVotes
    ) external whenNotPaused {
        AllocationVoting allocationVoting = AllocationVoting(getAddress("allocationVoting"));
        for (uint256 i = 0; i < _assets.length; i++) {
            allocationVoting.vote(msg.sender, _assets[i], _unwindingEpochs[i], _liquidVotes[i], _illiquidVotes[i]);
        }
    }
    function _revertIfThereAreUnaccruedLosses() internal view {
        YieldSharing yieldSharing = YieldSharing(getAddress("yieldSharing"));
        require(yieldSharing.unaccruedYield() >= 0, PendingLossesUnapplied());
    }
}
--- END FILE: ../infinify_certora_report/src/gateway/InfiniFiGatewayV1.sol ---
--- START FILE: ../infinify_certora_report/src/interfaces/IOracle.sol ---
pragma solidity 0.8.28;
interface IOracle {
    function price() external view returns (uint256);
}
--- END FILE: ../infinify_certora_report/src/interfaces/IOracle.sol ---
--- START FILE: ../infinify_certora_report/src/interfaces/IMintController.sol ---
pragma solidity 0.8.28;
interface IAfterMintHook {
    event AssetRebalanceThresholdUpdated(uint256 indexed timestamp, uint256 amount);
    function afterMint(address _to, uint256 _assetsIn) external;
}
interface IMintController {
    error AssetAmountTooLow(uint256 _amountIn, uint256 _minAssetAmount);
    event AfterMintHookChanged(uint256 indexed timestamp, address hook);
    event MinAssetAmountUpdated(uint256 indexed timestamp, uint256 amount);
    event Mint(uint256 indexed timestamp, address indexed to, address asset, uint256 amountIn, uint256 amountOut);
    function assetToReceipt(uint256 _assetAmount) external view returns (uint256);
    function mint(address _to, uint256 _assetAmountIn) external returns (uint256);
}
--- END FILE: ../infinify_certora_report/src/interfaces/IMintController.sol ---
--- START FILE: ../infinify_certora_report/src/interfaces/IFarm.sol ---
pragma solidity 0.8.28;
interface IFarm {
    event AssetsUpdated(uint256 timestamp, uint256 assetsBefore, uint256 assetsAfter);
    function cap() external view returns (uint256);
    function assetToken() external view returns (address);
    function assets() external view returns (uint256);
    function deposit() external;
    function maxDeposit() external view returns (uint256);
    function withdraw(uint256 amount, address to) external;
    function liquidity() external view returns (uint256);
}
--- END FILE: ../infinify_certora_report/src/interfaces/IFarm.sol ---
--- START FILE: ../infinify_certora_report/src/interfaces/IMaturityFarm.sol ---
pragma solidity 0.8.28;
import {IFarm} from "@interfaces/IFarm.sol";
interface IMaturityFarm is IFarm {
    function maturity() external view returns (uint256);
}
--- END FILE: ../infinify_certora_report/src/interfaces/IMaturityFarm.sol ---
--- START FILE: ../infinify_certora_report/src/interfaces/IRedeemController.sol ---
pragma solidity 0.8.28;
interface IBeforeRedeemHook {
    function beforeRedeem(address _to, uint256 _receiptAmountIn, uint256 _assetAmountOut) external;
}
interface IRedeemController {
    error RedeemAmountTooLow(uint256 _amountIn, uint256 _minRedemptionAmount);
    event BeforeRedeemHookChanged(uint256 indexed timestamp, address hook);
    event MinRedemptionAmountUpdated(uint256 indexed timestamp, uint256 amount);
    event Redeem(uint256 indexed timestamp, address indexed to, address asset, uint256 amountIn, uint256 amountOut);
    function receiptToAsset(uint256 _receiptAmount) external view returns (uint256);
    function redeem(address _to, uint256 _receiptAmountIn) external returns (uint256);
}
--- END FILE: ../infinify_certora_report/src/interfaces/IRedeemController.sol ---
--- START FILE: ../infinify_certora_report/src/interfaces/pendle/ISYToken.sol ---
pragma solidity 0.8.28;
interface ISYToken {
    function getAbsoluteSupplyCap() external view returns (uint256);
    function getAbsoluteTotalSupply() external view returns (uint256);
    function assetInfo() external view returns (uint8 assetType, address assetAddress, uint8 assetDecimals);
}
--- END FILE: ../infinify_certora_report/src/interfaces/pendle/ISYToken.sol ---
--- START FILE: ../infinify_certora_report/src/interfaces/pendle/IPendleOracle.sol ---
pragma solidity 0.8.28;
interface IPendleOracle {
    function getPtToSyRate(address market, uint32 twapDuration) external view returns (uint256);
    function getPtToAssetRate(address market, uint32 twapDuration) external view returns (uint256);
}
--- END FILE: ../infinify_certora_report/src/interfaces/pendle/IPendleOracle.sol ---
--- START FILE: ../infinify_certora_report/src/interfaces/pendle/IPendleMarket.sol ---
pragma solidity 0.8.28;
interface IPendleMarket {
    function readTokens() external view returns (address sy, address pt, address yt);
    function expiry() external view returns (uint256 timestamp);
}
--- END FILE: ../infinify_certora_report/src/interfaces/pendle/IPendleMarket.sol ---
--- START FILE: ../infinify_certora_report/src/interfaces/aave/IAddressProvider.sol ---
pragma solidity 0.8.28;
interface IAddressProvider {
    function getPoolDataProvider() external view returns (address);
}
--- END FILE: ../infinify_certora_report/src/interfaces/aave/IAddressProvider.sol ---
--- START FILE: ../infinify_certora_report/src/interfaces/aave/IAaveDataProvider.sol ---
pragma solidity 0.8.28;
interface IAaveDataProvider {
    function getReserveCaps(address asset) external view returns (uint256 borrowCap, uint256 supplyCap);
    struct AaveDataProviderReserveData {
        uint256 unbacked; 
        uint256 accruedToTreasuryScaled; 
        uint256 totalAToken; 
        uint256 totalStableDebt; 
        uint256 totalVariableDebt; 
        uint256 liquidityRate; 
        uint256 variableBorrowRate; 
        uint256 stableBorrowRate; 
        uint256 averageStableBorrowRate; 
        uint256 liquidityIndex; 
        uint256 variableBorrowIndex; 
        uint40 lastUpdateTimestamp; 
    }
    function getReserveData(address asset) external view returns (AaveDataProviderReserveData memory data);
    function getPaused(address asset) external view returns (bool isPaused);
}
--- END FILE: ../infinify_certora_report/src/interfaces/aave/IAaveDataProvider.sol ---
--- START FILE: ../infinify_certora_report/src/interfaces/aave/IAaveV3Pool.sol ---
pragma solidity 0.8.28;
interface IAaveV3Pool {
    function ADDRESSES_PROVIDER() external view returns (address);
    function supply(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;
    function withdraw(address asset, uint256 amount, address to) external returns (uint256);
}
--- END FILE: ../infinify_certora_report/src/interfaces/aave/IAaveV3Pool.sol ---
--- START FILE: ../infinify_certora_report/src/core/InfiniFiCore.sol ---
pragma solidity 0.8.28;
import {CoreRoles} from "@libraries/CoreRoles.sol";
import {AccessControlEnumerable} from "@openzeppelin/contracts/access/extensions/AccessControlEnumerable.sol";
contract InfiniFiCore is AccessControlEnumerable {
    error RoleAlreadyExists(bytes32 role);
    error RoleDoesNotExist(bytes32 role);
    error LengthMismatch(uint256 expected, uint256 actual);
    constructor() {
        _grantRole(CoreRoles.GOVERNOR, msg.sender);
        _setRoleAdmin(CoreRoles.GOVERNOR, CoreRoles.GOVERNOR);
        _setRoleAdmin(CoreRoles.PAUSE, CoreRoles.GOVERNOR);
        _setRoleAdmin(CoreRoles.UNPAUSE, CoreRoles.GOVERNOR);
        _setRoleAdmin(CoreRoles.PROTOCOL_PARAMETERS, CoreRoles.GOVERNOR);
        _setRoleAdmin(CoreRoles.MINOR_ROLES_MANAGER, CoreRoles.GOVERNOR);
        _setRoleAdmin(CoreRoles.ENTRY_POINT, CoreRoles.GOVERNOR);
        _setRoleAdmin(CoreRoles.RECEIPT_TOKEN_MINTER, CoreRoles.GOVERNOR);
        _setRoleAdmin(CoreRoles.RECEIPT_TOKEN_BURNER, CoreRoles.GOVERNOR);
        _setRoleAdmin(CoreRoles.LOCKED_TOKEN_MANAGER, CoreRoles.GOVERNOR);
        _setRoleAdmin(CoreRoles.TRANSFER_RESTRICTOR, CoreRoles.GOVERNOR);
        _setRoleAdmin(CoreRoles.FARM_MANAGER, CoreRoles.GOVERNOR);
        _setRoleAdmin(CoreRoles.MANUAL_REBALANCER, CoreRoles.GOVERNOR);
        _setRoleAdmin(CoreRoles.PERIODIC_REBALANCER, CoreRoles.GOVERNOR);
        _setRoleAdmin(CoreRoles.EMERGENCY_WITHDRAWAL, CoreRoles.GOVERNOR);
        _setRoleAdmin(CoreRoles.FARM_SWAP_CALLER, CoreRoles.GOVERNOR);
        _setRoleAdmin(CoreRoles.ORACLE_MANAGER, CoreRoles.GOVERNOR);
        _setRoleAdmin(CoreRoles.FINANCE_MANAGER, CoreRoles.GOVERNOR);
        _setRoleAdmin(CoreRoles.PROPOSER_ROLE, CoreRoles.GOVERNOR);
        _setRoleAdmin(CoreRoles.EXECUTOR_ROLE, CoreRoles.GOVERNOR);
        _setRoleAdmin(CoreRoles.CANCELLER_ROLE, CoreRoles.GOVERNOR);
    }
    function createRole(bytes32 role, bytes32 adminRole) external onlyRole(CoreRoles.GOVERNOR) {
        require(getRoleAdmin(role) == bytes32(0), RoleAlreadyExists(role));
        _setRoleAdmin(role, adminRole);
    }
    function setRoleAdmin(bytes32 role, bytes32 adminRole) external onlyRole(CoreRoles.GOVERNOR) {
        require(getRoleAdmin(role) != bytes32(0), RoleDoesNotExist(role));
        _setRoleAdmin(role, adminRole);
    }
    function grantRoles(bytes32[] calldata roles, address[] calldata accounts) external {
        require(roles.length == accounts.length, LengthMismatch(roles.length, accounts.length));
        for (uint256 i = 0; i < roles.length; i++) {
            _checkRole(getRoleAdmin(roles[i]));
            _grantRole(roles[i], accounts[i]);
        }
    }
}
--- END FILE: ../infinify_certora_report/src/core/InfiniFiCore.sol ---
--- START FILE: ../infinify_certora_report/src/core/CoreControlled.sol ---
pragma solidity 0.8.28;
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {CoreRoles} from "@libraries/CoreRoles.sol";
import {InfiniFiCore} from "@core/InfiniFiCore.sol";
abstract contract CoreControlled is Pausable {
    error UnderlyingCallReverted(bytes returnData);
    event CoreUpdate(address indexed oldCore, address indexed newCore);
    InfiniFiCore private _core;
    constructor(address coreAddress) {
        _core = InfiniFiCore(coreAddress);
    }
    modifier onlyCoreRole(bytes32 role) {
        require(_core.hasRole(role, msg.sender), "UNAUTHORIZED");
        _;
    }
    function core() public view returns (InfiniFiCore) {
        return _core;
    }
    function setCore(address newCore) external onlyCoreRole(CoreRoles.GOVERNOR) {
        _setCore(newCore);
    }
    function _setCore(address newCore) internal {
        address oldCore = address(_core);
        _core = InfiniFiCore(newCore);
        emit CoreUpdate(oldCore, newCore);
    }
    function pause() public onlyCoreRole(CoreRoles.PAUSE) {
        _pause();
    }
    function unpause() public onlyCoreRole(CoreRoles.UNPAUSE) {
        _unpause();
    }
    struct Call {
        address target;
        uint256 value;
        bytes callData;
    }
    function emergencyAction(Call[] calldata calls)
        external
        payable
        virtual
        onlyCoreRole(CoreRoles.GOVERNOR)
        returns (bytes[] memory returnData)
    {
        returnData = new bytes[](calls.length);
        for (uint256 i = 0; i < calls.length; i++) {
            address payable target = payable(calls[i].target);
            uint256 value = calls[i].value;
            bytes calldata callData = calls[i].callData;
            (bool success, bytes memory returned) = target.call{value: value}(callData);
            require(success, UnderlyingCallReverted(returned));
            returnData[i] = returned;
        }
    }
}
--- END FILE: ../infinify_certora_report/src/core/CoreControlled.sol ---
--- START FILE: ../infinify_certora_report/src/locking/LockingController.sol ---
pragma solidity 0.8.28;
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {FixedPointMathLib} from "@solmate/src/utils/FixedPointMathLib.sol";
import {CoreRoles} from "@libraries/CoreRoles.sol";
import {CoreControlled} from "@core/CoreControlled.sol";
import {UnwindingModule} from "@locking/UnwindingModule.sol";
import {LockedPositionToken} from "@tokens/LockedPositionToken.sol";
contract LockingController is CoreControlled {
    using FixedPointMathLib for uint256;
    address public immutable receiptToken;
    address public immutable unwindingModule;
    struct BucketData {
        address shareToken;
        uint256 totalReceiptTokens;
        uint256 multiplier;
    }
    error TransferFailed();
    error InvalidBucket(uint32 unwindingEpochs);
    error InvalidUnwindingEpochs(uint32 unwindingEpochs);
    error InvalidMultiplier(uint256 multiplier);
    error BucketMustBeLongerDuration(uint32 oldValue, uint32 newValue);
    error UnwindingInProgress();
    error InvalidMaxLossPercentage(uint256 maxLossPercentage);
    event PositionCreated(
        uint256 indexed timestamp, address indexed user, uint256 amount, uint32 indexed unwindingEpochs
    );
    event PositionRemoved(
        uint256 indexed timestamp, address indexed user, uint256 amount, uint32 indexed unwindingEpochs
    );
    event RewardsDeposited(uint256 indexed timestamp, uint256 amount);
    event LossesApplied(uint256 indexed timestamp, uint256 amount);
    event BucketEnabled(uint256 indexed timestamp, uint256 bucket, address shareToken, uint256 multiplier);
    event BucketMultiplierUpdated(uint256 indexed timestamp, uint256 bucket, uint256 multiplier);
    event MaxLossPercentageUpdated(uint256 indexed timestamp, uint256 maxLossPercentage);
    uint32[] public enabledBuckets;
    mapping(uint32 _unwindingEpochs => BucketData data) public buckets;
    uint256 public globalReceiptToken;
    uint256 public globalRewardWeight;
    uint256 public maxLossPercentage = 0.999999e18;
    constructor(address _core, address _receiptToken, address _unwindingModule) CoreControlled(_core) {
        receiptToken = _receiptToken;
        unwindingModule = _unwindingModule;
    }
    function enableBucket(uint32 _unwindingEpochs, address _shareToken, uint256 _multiplier)
        external
        onlyCoreRole(CoreRoles.GOVERNOR)
    {
        require(buckets[_unwindingEpochs].shareToken == address(0), InvalidBucket(_unwindingEpochs));
        require(_unwindingEpochs > 0, InvalidUnwindingEpochs(_unwindingEpochs));
        require(_unwindingEpochs <= 100, InvalidUnwindingEpochs(_unwindingEpochs));
        require(_multiplier >= FixedPointMathLib.WAD, InvalidMultiplier(_multiplier));
        require(_multiplier <= 2 * FixedPointMathLib.WAD, InvalidMultiplier(_multiplier));
        buckets[_unwindingEpochs].shareToken = _shareToken;
        buckets[_unwindingEpochs].multiplier = _multiplier;
        enabledBuckets.push(_unwindingEpochs);
        emit BucketEnabled(block.timestamp, _unwindingEpochs, _shareToken, _multiplier);
    }
    function setBucketMultiplier(uint32 _unwindingEpochs, uint256 _multiplier)
        external
        onlyCoreRole(CoreRoles.GOVERNOR)
    {
        BucketData memory data = buckets[_unwindingEpochs];
        require(data.shareToken != address(0), InvalidBucket(_unwindingEpochs));
        require(_multiplier >= FixedPointMathLib.WAD, InvalidMultiplier(_multiplier));
        require(_multiplier <= 2 * FixedPointMathLib.WAD, InvalidMultiplier(_multiplier));
        uint256 oldRewardWeight = data.totalReceiptTokens.mulWadDown(data.multiplier);
        uint256 newRewardWeight = data.totalReceiptTokens.mulWadDown(_multiplier);
        globalRewardWeight = globalRewardWeight + newRewardWeight - oldRewardWeight;
        buckets[_unwindingEpochs].multiplier = _multiplier;
        emit BucketMultiplierUpdated(block.timestamp, _unwindingEpochs, _multiplier);
    }
    function setMaxLossPercentage(uint256 _maxLossPercentage) external onlyCoreRole(CoreRoles.GOVERNOR) {
        require(_maxLossPercentage <= FixedPointMathLib.WAD, InvalidMaxLossPercentage(_maxLossPercentage));
        maxLossPercentage = _maxLossPercentage;
        emit MaxLossPercentageUpdated(block.timestamp, _maxLossPercentage);
    }
    function getEnabledBuckets() external view returns (uint32[] memory) {
        return enabledBuckets;
    }
    function balanceOf(address _user) external view returns (uint256) {
        return _userSumAcrossUnwindingEpochs(_user, _totalReceiptTokensGetter);
    }
    function rewardWeight(address _user) external view returns (uint256) {
        return _userSumAcrossUnwindingEpochs(_user, _bucketRewardWeightGetter);
    }
    function rewardWeightForUnwindingEpochs(address _user, uint32 _unwindingEpochs) external view returns (uint256) {
        BucketData memory data = buckets[_unwindingEpochs];
        uint256 userShares = IERC20(data.shareToken).balanceOf(_user);
        uint256 totalShares = IERC20(data.shareToken).totalSupply();
        if (totalShares == 0) return 0;
        uint256 bucketRewardWeight = data.totalReceiptTokens.mulWadDown(data.multiplier);
        return userShares.mulDivDown(bucketRewardWeight, totalShares);
    }
    function shares(address _user, uint32 _unwindingEpochs) external view returns (uint256) {
        BucketData memory data = buckets[_unwindingEpochs];
        if (data.shareToken == address(0)) return 0;
        return IERC20(data.shareToken).balanceOf(_user);
    }
    function shareToken(uint32 _unwindingEpochs) external view returns (address) {
        return buckets[_unwindingEpochs].shareToken;
    }
    function exchangeRate(uint32 _unwindingEpochs) external view returns (uint256) {
        BucketData memory data = buckets[_unwindingEpochs];
        if (data.shareToken == address(0)) return 0;
        uint256 totalShares = IERC20(data.shareToken).totalSupply();
        if (totalShares == 0) return 0;
        return data.totalReceiptTokens.divWadDown(totalShares);
    }
    function unwindingEpochsEnabled(uint32 _unwindingEpochs) external view returns (bool) {
        return buckets[_unwindingEpochs].shareToken != address(0);
    }
    function totalBalance() public view returns (uint256) {
        return globalReceiptToken + UnwindingModule(unwindingModule).totalReceiptTokens();
    }
    function rewardMultiplier() external view returns (uint256) {
        uint256 totalWeight = globalRewardWeight + UnwindingModule(unwindingModule).totalRewardWeight();
        if (totalWeight == 0) return FixedPointMathLib.WAD; 
        return totalWeight.divWadDown(totalBalance());
    }
    function createPosition(uint256 _amount, uint32 _unwindingEpochs, address _recipient) external whenNotPaused {
        if (msg.sender != unwindingModule) {
            require(core().hasRole(CoreRoles.ENTRY_POINT, msg.sender), "UNAUTHORIZED");
        }
        BucketData memory data = buckets[_unwindingEpochs];
        require(data.shareToken != address(0), InvalidBucket(_unwindingEpochs));
        require(IERC20(receiptToken).transferFrom(msg.sender, address(this), _amount), TransferFailed());
        uint256 totalShares = IERC20(data.shareToken).totalSupply();
        uint256 newShares = totalShares == 0 ? _amount : _amount.mulDivDown(totalShares, data.totalReceiptTokens);
        uint256 bucketRewardWeightBefore = data.totalReceiptTokens.mulWadDown(data.multiplier);
        data.totalReceiptTokens += _amount;
        globalReceiptToken += _amount;
        buckets[_unwindingEpochs] = data;
        uint256 bucketRewardWeightAfter = data.totalReceiptTokens.mulWadDown(data.multiplier);
        globalRewardWeight += bucketRewardWeightAfter - bucketRewardWeightBefore;
        LockedPositionToken(data.shareToken).mint(_recipient, newShares);
        emit PositionCreated(block.timestamp, _recipient, _amount, _unwindingEpochs);
    }
    function startUnwinding(uint256 _shares, uint32 _unwindingEpochs, address _recipient)
        external
        whenNotPaused
        onlyCoreRole(CoreRoles.ENTRY_POINT)
    {
        BucketData memory data = buckets[_unwindingEpochs];
        require(data.shareToken != address(0), InvalidBucket(_unwindingEpochs));
        uint256 totalShares = IERC20(data.shareToken).totalSupply();
        uint256 userReceiptToken = _shares.mulDivDown(data.totalReceiptTokens, totalShares);
        require(IERC20(data.shareToken).transferFrom(msg.sender, address(this), _shares), TransferFailed());
        LockedPositionToken(data.shareToken).burn(_shares);
        UnwindingModule(unwindingModule).startUnwinding(
            _recipient, userReceiptToken, _unwindingEpochs, userReceiptToken.mulWadDown(data.multiplier)
        );
        IERC20(receiptToken).transfer(unwindingModule, userReceiptToken);
        buckets[_unwindingEpochs].totalReceiptTokens = data.totalReceiptTokens - userReceiptToken;
        uint256 bucketRewardWeightBefore = data.totalReceiptTokens.mulWadDown(data.multiplier);
        uint256 bucketRewardWeightAfter = (data.totalReceiptTokens - userReceiptToken).mulWadDown(data.multiplier);
        uint256 rewardWeightDecrease = bucketRewardWeightBefore - bucketRewardWeightAfter;
        globalRewardWeight -= rewardWeightDecrease;
        globalReceiptToken -= userReceiptToken;
        emit PositionRemoved(block.timestamp, _recipient, userReceiptToken, _unwindingEpochs);
    }
    function increaseUnwindingEpochs(
        uint256 _shares,
        uint32 _oldUnwindingEpochs,
        uint32 _newUnwindingEpochs,
        address _recipient
    ) external whenNotPaused onlyCoreRole(CoreRoles.ENTRY_POINT) {
        require(
            _newUnwindingEpochs > _oldUnwindingEpochs,
            BucketMustBeLongerDuration(_oldUnwindingEpochs, _newUnwindingEpochs)
        );
        BucketData memory oldData = buckets[_oldUnwindingEpochs];
        BucketData memory newData = buckets[_newUnwindingEpochs];
        require(newData.shareToken != address(0), InvalidBucket(_newUnwindingEpochs));
        if (_shares == 0) return;
        uint256 oldTotalSupply = IERC20(oldData.shareToken).totalSupply();
        uint256 receiptTokens = _shares.mulDivDown(oldData.totalReceiptTokens, oldTotalSupply);
        if (receiptTokens == 0) return;
        {
            uint256 oldBucketRewardWeightBefore = oldData.totalReceiptTokens.mulWadDown(oldData.multiplier);
            uint256 oldBucketRewardWeightAfter =
                (oldData.totalReceiptTokens - receiptTokens).mulWadDown(oldData.multiplier);
            uint256 newBucketRewardWeightBefore = newData.totalReceiptTokens.mulWadDown(newData.multiplier);
            uint256 newBucketRewardWeightAfter =
                (newData.totalReceiptTokens + receiptTokens).mulWadDown(newData.multiplier);
            uint256 _globalRewardWeight = globalRewardWeight;
            _globalRewardWeight = _globalRewardWeight - oldBucketRewardWeightBefore + oldBucketRewardWeightAfter;
            _globalRewardWeight = _globalRewardWeight - newBucketRewardWeightBefore + newBucketRewardWeightAfter;
            globalRewardWeight = _globalRewardWeight;
        }
        ERC20Burnable(oldData.shareToken).burnFrom(msg.sender, _shares);
        oldData.totalReceiptTokens -= receiptTokens;
        buckets[_oldUnwindingEpochs] = oldData;
        uint256 newTotalSupply = IERC20(newData.shareToken).totalSupply();
        uint256 newShares =
            newTotalSupply == 0 ? receiptTokens : receiptTokens.mulDivDown(newTotalSupply, newData.totalReceiptTokens);
        LockedPositionToken(newData.shareToken).mint(_recipient, newShares);
        newData.totalReceiptTokens += receiptTokens;
        buckets[_newUnwindingEpochs] = newData;
        emit PositionRemoved(block.timestamp, _recipient, receiptTokens, _oldUnwindingEpochs);
        emit PositionCreated(block.timestamp, _recipient, receiptTokens, _newUnwindingEpochs);
    }
    function cancelUnwinding(address _user, uint256 _unwindingTimestamp, uint32 _newUnwindingEpochs)
        external
        whenNotPaused
        onlyCoreRole(CoreRoles.ENTRY_POINT)
    {
        UnwindingModule(unwindingModule).cancelUnwinding(_user, _unwindingTimestamp, _newUnwindingEpochs);
    }
    function withdraw(address _user, uint256 _unwindingTimestamp)
        external
        whenNotPaused
        onlyCoreRole(CoreRoles.ENTRY_POINT)
    {
        UnwindingModule(unwindingModule).withdraw(_unwindingTimestamp, _user);
    }
    function _userSumAcrossUnwindingEpochs(address _user, function(BucketData memory) view returns (uint256) _getter)
        internal
        view
        returns (uint256)
    {
        uint256 weight;
        uint256 nBuckets = enabledBuckets.length;
        for (uint256 i = 0; i < nBuckets; i++) {
            uint32 unwindingEpochs = enabledBuckets[i];
            BucketData memory data = buckets[unwindingEpochs];
            uint256 userShares = IERC20(data.shareToken).balanceOf(_user);
            if (userShares == 0) continue;
            uint256 totalShares = IERC20(data.shareToken).totalSupply();
            if (totalShares == 0) continue;
            weight += userShares.mulDivDown(_getter(data), totalShares);
        }
        return weight;
    }
    function _bucketRewardWeightGetter(BucketData memory data) internal pure returns (uint256) {
        return data.totalReceiptTokens.mulWadDown(data.multiplier);
    }
    function _totalReceiptTokensGetter(BucketData memory data) internal pure returns (uint256) {
        return data.totalReceiptTokens;
    }
    function _min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
    function depositRewards(uint256 _amount) external onlyCoreRole(CoreRoles.FINANCE_MANAGER) {
        if (_amount == 0) return;
        emit RewardsDeposited(block.timestamp, _amount);
        require(IERC20(receiptToken).transferFrom(msg.sender, address(this), _amount), TransferFailed());
        uint256 _globalRewardWeight = globalRewardWeight;
        uint256 unwindingRewardWeight = UnwindingModule(unwindingModule).totalRewardWeight();
        uint256 unwindingRewards =
            _amount.mulDivDown(unwindingRewardWeight, _globalRewardWeight + unwindingRewardWeight);
        if (unwindingRewards > 0) {
            UnwindingModule(unwindingModule).depositRewards(unwindingRewards);
            require(IERC20(receiptToken).transfer(unwindingModule, unwindingRewards), TransferFailed());
            _amount -= unwindingRewards;
            if (_amount == 0) return;
        }
        if (_globalRewardWeight == 0) return;
        uint256 _newGlobalRewardWeight = 0;
        uint256 _receiptTokensIncrement = 0;
        uint256 nBuckets = enabledBuckets.length;
        for (uint256 i = 0; i < nBuckets; i++) {
            BucketData storage data = buckets[enabledBuckets[i]];
            uint256 epochTotalReceiptToken = data.totalReceiptTokens;
            uint256 bucketRewardWeight = epochTotalReceiptToken.mulWadDown(data.multiplier);
            uint256 allocation = _amount.mulDivDown(bucketRewardWeight, _globalRewardWeight);
            data.totalReceiptTokens = epochTotalReceiptToken + allocation;
            _receiptTokensIncrement += allocation;
            _newGlobalRewardWeight += (epochTotalReceiptToken + allocation).mulWadDown(data.multiplier);
        }
        globalReceiptToken += _receiptTokensIncrement;
        globalRewardWeight = _newGlobalRewardWeight;
    }
    function applyLosses(uint256 _amount) external onlyCoreRole(CoreRoles.FINANCE_MANAGER) {
        if (_amount == 0) return;
        emit LossesApplied(block.timestamp, _amount);
        uint256 unwindingBalance = UnwindingModule(unwindingModule).totalReceiptTokens();
        uint256 _globalReceiptToken = globalReceiptToken;
        uint256 _totalBalance = _globalReceiptToken + unwindingBalance;
        {
            uint256 maximumAllowedLoss = _totalBalance.mulDivDown(maxLossPercentage, 1e18);
            if (_amount > maximumAllowedLoss) {
                UnwindingModule(unwindingModule).applyLosses(unwindingBalance);
                ERC20Burnable(receiptToken).burn(_globalReceiptToken);
                globalReceiptToken = 0;
                globalRewardWeight = 0;
                _pause();
                return;
            }
        }
        uint256 amountToUnwinding = _amount.mulDivUp(unwindingBalance, _totalBalance);
        amountToUnwinding = _min(amountToUnwinding, unwindingBalance);
        UnwindingModule(unwindingModule).applyLosses(amountToUnwinding);
        _amount -= amountToUnwinding;
        if (_amount == 0) return;
        _amount = _min(_amount, _globalReceiptToken);
        ERC20Burnable(receiptToken).burn(_amount);
        uint256 nBuckets = enabledBuckets.length;
        uint256 newGlobalRewardWeight = 0;
        uint256 globalReceiptTokenDecrement = 0;
        for (uint256 i = 0; i < nBuckets; i++) {
            BucketData storage data = buckets[enabledBuckets[i]];
            uint256 epochTotalReceiptToken = data.totalReceiptTokens;
            if (epochTotalReceiptToken == 0) continue;
            uint256 allocation = epochTotalReceiptToken.mulDivUp(_amount, _globalReceiptToken);
            allocation = _min(allocation, epochTotalReceiptToken); 
            data.totalReceiptTokens = epochTotalReceiptToken - allocation;
            globalReceiptTokenDecrement += allocation;
            newGlobalRewardWeight += (epochTotalReceiptToken - allocation).mulWadDown(data.multiplier);
        }
        globalReceiptToken = _globalReceiptToken - globalReceiptTokenDecrement;
        globalRewardWeight = newGlobalRewardWeight;
        {
            uint256 slashIndex = UnwindingModule(unwindingModule).slashIndex();
            bool unwindingWipedOut = amountToUnwinding > 0 && slashIndex == 0;
            if (unwindingWipedOut) _pause();
        }
    }
}
--- END FILE: ../infinify_certora_report/src/locking/LockingController.sol ---
--- START FILE: ../infinify_certora_report/src/locking/UnwindingModule.sol ---
pragma solidity 0.8.28;
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {FixedPointMathLib} from "@solmate/src/utils/FixedPointMathLib.sol";
import {EpochLib} from "@libraries/EpochLib.sol";
import {CoreRoles} from "@libraries/CoreRoles.sol";
import {CoreControlled} from "@core/CoreControlled.sol";
import {LockingController} from "@locking/LockingController.sol";
struct UnwindingPosition {
    uint256 shares; 
    uint32 fromEpoch; 
    uint32 toEpoch; 
    uint256 fromRewardWeight; 
    uint256 rewardWeightDecrease; 
}
struct GlobalPoint {
    uint32 epoch; 
    uint256 totalRewardWeight; 
    uint256 totalRewardWeightDecrease; 
    uint256 rewardShares; 
}
contract UnwindingModule is CoreControlled {
    using EpochLib for uint256;
    using FixedPointMathLib for uint256;
    error TransferFailed();
    error UserNotUnwinding();
    error UserUnwindingNotStarted();
    error UserUnwindingInprogress();
    error InvalidUnwindingEpochs(uint32 value);
    event UnwindingStarted(
        uint256 indexed timestamp, address user, uint256 receiptTokens, uint32 unwindingEpochs, uint256 rewardWeight
    );
    event UnwindingCanceled(
        uint256 indexed timestamp, address user, uint256 startUnwindingTimestamp, uint32 newUnwindingEpochs
    );
    event Withdrawal(uint256 indexed timestamp, uint256 startUnwindingTimestamp, address user);
    event GlobalPointUpdated(uint256 indexed timestamp, GlobalPoint);
    event CriticalLoss(uint256 indexed timestamp, uint256 amount);
    address public immutable receiptToken;
    uint256 public totalShares;
    uint256 public totalReceiptTokens;
    uint256 public slashIndex = FixedPointMathLib.WAD;
    mapping(bytes32 id => UnwindingPosition position) public positions;
    uint32 public lastGlobalPointEpoch;
    mapping(uint32 epoch => GlobalPoint point) public globalPoints;
    mapping(uint32 epoch => uint256 increase) public rewardWeightBiasIncreases;
    mapping(uint32 epoch => uint256 increase) public rewardWeightIncreases;
    mapping(uint32 epoch => uint256 decrease) public rewardWeightDecreases;
    constructor(address _core, address _receiptToken) CoreControlled(_core) {
        receiptToken = _receiptToken;
        uint32 currentEpoch = uint32(block.timestamp.epoch());
        lastGlobalPointEpoch = currentEpoch;
        globalPoints[currentEpoch] =
            GlobalPoint({epoch: currentEpoch, totalRewardWeight: 0, totalRewardWeightDecrease: 0, rewardShares: 0});
    }
    function totalRewardWeight() external view returns (uint256) {
        GlobalPoint memory point = _getLastGlobalPoint();
        return point.totalRewardWeight.mulWadDown(slashIndex);
    }
    function balanceOf(address _user, uint256 _startUnwindingTimestamp) external view returns (uint256) {
        return _sharesToAmount(_userShares(_user, _startUnwindingTimestamp));
    }
    function _userShares(address _user, uint256 _startUnwindingTimestamp) internal view returns (uint256) {
        UnwindingPosition memory position = positions[_unwindingId(_user, _startUnwindingTimestamp)];
        if (position.fromEpoch == 0) return 0;
        GlobalPoint memory globalPoint;
        uint256 userRewardWeight = position.fromRewardWeight;
        uint256 userShares = position.shares;
        uint256 currentEpoch = block.timestamp.epoch();
        for (uint32 epoch = position.fromEpoch - 1; epoch <= currentEpoch; epoch++) {
            GlobalPoint memory epochGlobalPoint = globalPoints[epoch];
            if (epochGlobalPoint.epoch != 0) globalPoint = epochGlobalPoint;
            if (epoch >= position.fromEpoch) {
                userShares += globalPoint.rewardShares.mulDivDown(userRewardWeight, globalPoint.totalRewardWeight);
            }
            globalPoint.totalRewardWeightDecrease -= rewardWeightIncreases[epoch];
            globalPoint.totalRewardWeightDecrease += rewardWeightDecreases[epoch];
            globalPoint.totalRewardWeight += rewardWeightBiasIncreases[epoch];
            globalPoint.totalRewardWeight -= globalPoint.totalRewardWeightDecrease;
            globalPoint.epoch = epoch + 1;
            globalPoint.rewardShares = 0;
            if (epoch >= position.fromEpoch && epoch < position.toEpoch) {
                userRewardWeight -= position.rewardWeightDecrease;
            }
        }
        return userShares;
    }
    function rewardWeight(address _user, uint256 _startUnwindingTimestamp) public view returns (uint256) {
        UnwindingPosition memory position = positions[_unwindingId(_user, _startUnwindingTimestamp)];
        if (position.fromEpoch == 0) return 0;
        uint256 userRewardWeight = position.fromRewardWeight;
        uint256 currentEpoch = block.timestamp.epoch();
        if (currentEpoch < position.fromEpoch) return 0;
        for (uint32 epoch = position.fromEpoch + 1; epoch <= currentEpoch && epoch <= position.toEpoch; epoch++) {
            userRewardWeight -= position.rewardWeightDecrease;
        }
        return userRewardWeight.mulWadDown(slashIndex);
    }
    function startUnwinding(address _user, uint256 _receiptTokens, uint32 _unwindingEpochs, uint256 _rewardWeight)
        external
        onlyCoreRole(CoreRoles.LOCKED_TOKEN_MANAGER)
    {
        bytes32 id = _unwindingId(_user, block.timestamp);
        require(positions[id].fromEpoch == 0, UserUnwindingInprogress());
        uint256 userRewardWeight = _rewardWeight.divWadDown(slashIndex);
        uint256 targetRewardWeight = _receiptTokens.divWadDown(slashIndex);
        uint256 totalDecrease = userRewardWeight - targetRewardWeight;
        uint256 rewardWeightDecrease = totalDecrease / uint256(_unwindingEpochs);
        uint256 roundingLoss = totalDecrease - (rewardWeightDecrease * uint256(_unwindingEpochs));
        userRewardWeight -= roundingLoss;
        uint32 nextEpoch = uint32(block.timestamp.nextEpoch());
        uint32 endEpoch = nextEpoch + _unwindingEpochs;
        {
            uint256 newShares = _amountToShares(_receiptTokens);
            positions[id] = UnwindingPosition({
                shares: newShares,
                fromEpoch: nextEpoch,
                toEpoch: endEpoch,
                fromRewardWeight: userRewardWeight,
                rewardWeightDecrease: rewardWeightDecrease
            });
            totalShares += newShares;
        }
        totalReceiptTokens += _receiptTokens;
        GlobalPoint memory point = _getLastGlobalPoint();
        _updateGlobalPoint(point);
        rewardWeightBiasIncreases[uint32(block.timestamp.epoch())] += userRewardWeight;
        rewardWeightDecreases[nextEpoch] += rewardWeightDecrease;
        rewardWeightIncreases[endEpoch] += rewardWeightDecrease;
        emit UnwindingStarted(block.timestamp, _user, _receiptTokens, _unwindingEpochs, userRewardWeight);
    }
    function cancelUnwinding(address _user, uint256 _startUnwindingTimestamp, uint32 _newUnwindingEpochs)
        external
        onlyCoreRole(CoreRoles.LOCKED_TOKEN_MANAGER)
    {
        uint32 currentEpoch = uint32(block.timestamp.epoch());
        bytes32 id = _unwindingId(_user, _startUnwindingTimestamp);
        UnwindingPosition memory position = positions[id];
        require(position.toEpoch > 0 && currentEpoch < position.toEpoch, UserNotUnwinding());
        require(currentEpoch >= position.fromEpoch, UserUnwindingNotStarted());
        uint256 userShares = _userShares(_user, _startUnwindingTimestamp);
        uint256 userBalance = _sharesToAmount(userShares);
        uint256 elapsedEpochs = currentEpoch - position.fromEpoch;
        uint256 userRewardWeight = position.fromRewardWeight - elapsedEpochs * position.rewardWeightDecrease;
        {
            GlobalPoint memory point = _getLastGlobalPoint();
            if (currentEpoch == position.fromEpoch) {
                rewardWeightDecreases[currentEpoch] -= position.rewardWeightDecrease;
            } else {
                point.totalRewardWeightDecrease -= position.rewardWeightDecrease;
            }
            uint256 rewardSharesToDecrement = point.rewardShares.mulDivDown(userRewardWeight, point.totalRewardWeight);
            point.rewardShares -= rewardSharesToDecrement;
            point.totalRewardWeight -= userRewardWeight;
            _updateGlobalPoint(point);
            rewardWeightIncreases[position.toEpoch] -= position.rewardWeightDecrease;
            delete positions[id];
            totalShares -= userShares;
            totalReceiptTokens -= userBalance;
        }
        uint32 remainingEpochs = position.toEpoch - currentEpoch;
        require(_newUnwindingEpochs >= remainingEpochs, InvalidUnwindingEpochs(_newUnwindingEpochs));
        IERC20(receiptToken).approve(msg.sender, userBalance);
        LockingController(msg.sender).createPosition(userBalance, _newUnwindingEpochs, _user);
        emit UnwindingCanceled(block.timestamp, _user, _startUnwindingTimestamp, _newUnwindingEpochs);
    }
    function withdraw(uint256 _startUnwindingTimestamp, address _owner)
        external
        onlyCoreRole(CoreRoles.LOCKED_TOKEN_MANAGER)
    {
        uint32 currentEpoch = uint32(block.timestamp.epoch());
        bytes32 id = _unwindingId(_owner, _startUnwindingTimestamp);
        UnwindingPosition memory position = positions[id];
        require(position.toEpoch > 0, UserNotUnwinding());
        require(currentEpoch >= position.toEpoch, UserUnwindingInprogress());
        uint256 userShares = _userShares(_owner, _startUnwindingTimestamp);
        uint256 userBalance = _sharesToAmount(userShares);
        uint256 userRewardWeight =
            position.fromRewardWeight - (position.toEpoch - position.fromEpoch) * position.rewardWeightDecrease;
        delete positions[id];
        GlobalPoint memory point = _getLastGlobalPoint();
        uint256 rewardSharesToDecrement = point.rewardShares.mulDivDown(userRewardWeight, point.totalRewardWeight);
        point.rewardShares -= rewardSharesToDecrement;
        point.totalRewardWeight -= userRewardWeight;
        _updateGlobalPoint(point);
        totalShares -= userShares;
        totalReceiptTokens -= userBalance;
        require(IERC20(receiptToken).transfer(_owner, userBalance), TransferFailed());
        emit Withdrawal(block.timestamp, _startUnwindingTimestamp, _owner);
    }
    function _unwindingId(address _user, uint256 _blockTimestamp) internal pure returns (bytes32) {
        return keccak256(abi.encode(_user, _blockTimestamp));
    }
    function _amountToShares(uint256 _amount) internal view returns (uint256) {
        uint256 _totalReceiptTokens = totalReceiptTokens;
        return _totalReceiptTokens == 0 ? _amount : _amount.mulDivDown(totalShares, _totalReceiptTokens);
    }
    function _sharesToAmount(uint256 _shares) internal view returns (uint256) {
        if (_shares == 0) return 0;
        return _shares.mulDivDown(totalReceiptTokens, totalShares);
    }
    function _getLastGlobalPoint() internal view returns (GlobalPoint memory) {
        GlobalPoint memory point = globalPoints[lastGlobalPointEpoch];
        uint32 currentEpoch = uint32(block.timestamp.epoch());
        for (uint32 epoch = point.epoch; epoch < currentEpoch; epoch++) {
            point.totalRewardWeightDecrease -= rewardWeightIncreases[epoch];
            point.totalRewardWeightDecrease += rewardWeightDecreases[epoch];
            point.totalRewardWeight += rewardWeightBiasIncreases[epoch];
            point.totalRewardWeight -= point.totalRewardWeightDecrease;
            point.epoch = epoch + 1;
            point.rewardShares = 0;
        }
        return point;
    }
    function _updateGlobalPoint(GlobalPoint memory point) internal {
        globalPoints[point.epoch] = point;
        lastGlobalPointEpoch = point.epoch;
        emit GlobalPointUpdated(block.timestamp, point);
    }
    function depositRewards(uint256 _amount) external onlyCoreRole(CoreRoles.LOCKED_TOKEN_MANAGER) {
        if (_amount == 0) return;
        GlobalPoint memory point = _getLastGlobalPoint();
        uint256 rewardShares = _amountToShares(_amount);
        point.rewardShares += rewardShares;
        _updateGlobalPoint(point);
        totalShares += rewardShares;
        totalReceiptTokens += _amount;
    }
    function applyLosses(uint256 _amount) external onlyCoreRole(CoreRoles.LOCKED_TOKEN_MANAGER) {
        if (_amount == 0) return;
        if (_amount > totalReceiptTokens) {
            _amount = totalReceiptTokens;
            emit CriticalLoss(block.timestamp, _amount);
        }
        uint256 _totalReceiptTokens = totalReceiptTokens;
        ERC20Burnable(receiptToken).burn(_amount);
        slashIndex = slashIndex.mulDivDown(_totalReceiptTokens - _amount, _totalReceiptTokens);
        totalReceiptTokens = _totalReceiptTokens - _amount;
    }
}
--- END FILE: ../infinify_certora_report/src/locking/UnwindingModule.sol ---