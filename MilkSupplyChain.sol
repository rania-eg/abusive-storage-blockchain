// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";


contract MilkSupplyChain is Ownable {
    struct Batch {
        uint256 id;
        address producer;
        uint256 quantity;
        uint256 timestamp;
        address currentOwner;
        bool expired;
    }
    enum ViolationType {
    ExcessiveStorage,
    QuantityOverflow
}

    struct StorageViolation {
        ViolationType violationType;
        address holder;
        uint256 batchId;
        uint256 detectionTime;
        bool resolved;
    }
    struct Position{
        uint256 latitude;
        uint256 longitude;
    }

    uint256 public totalResellers=0;
    uint256 public totalProducers=0;
    uint256 public totalViolations=0;
    uint256 public maxStorageDuration = 30 days;
    uint256 public nextBatchId;
    uint256 public nextViolationId;
    
    mapping(uint256 => Batch) public batches;
    mapping(address => uint256) public stockBalance;
    mapping(address => uint256[]) public batchesByOwner;
    
    // Role management
    mapping(address => bool) public isAdmin;
    mapping(address => bool) public isReseller;
    mapping(address => uint256) public maxQuantityPerReseller;
    mapping(address => bool) public isProducer;
    mapping(address => string) public addressName;
    mapping(address=> Position) public addressPosition;
    // mappings mtaa violations
    mapping(uint256 => StorageViolation) public violations;
    mapping(address => uint256[]) public violationsByHolder;
    mapping(address => bool) public blacklistedHolders;
    uint256 public violationThreshold = 3; // 9d'h men violation 9bal me yetbanna
    
    // Events
    event Produced(uint256 batchId, address indexed producer, uint256 quantity, uint256 timestamp);
    event ResellerChanged(address indexed reseller, address indexed admin, uint256 maxQuantity, uint256 timestamp);
    event Transferred(address indexed from, address indexed to, uint256 quantity, uint256 batchId);
    event AdminAdded(address indexed admin);
    event AdminRemoved(address indexed admin);
    event ResellerAdded(address indexed reseller);
    event ProducerAdded(address indexed producer);
    event ResellerRemoved(address indexed reseller);
    event ProducerRemoved(address indexed producer);
    event BatchExpired(uint256 indexed batchId, address indexed owner, uint256 expiryTime);
    event MaxStorageDurationChanged(uint256 oldDuration, uint256 newDuration);
    event AbusiveStorageDetected(uint256 indexed violationId, address indexed holder, uint256 indexed batchId, uint256 detectionTime);
    event ViolationResolved(uint256 indexed violationId, address indexed resolver);
    event HolderBlacklisted(address indexed holder, uint256 violationCount);
    event HolderRemovedFromBlacklist(address indexed holder);
    event ViolationThresholdChanged(uint256 oldThreshold, uint256 newThreshold);
    
    modifier onlyAdmin() {
        require(isAdmin[msg.sender] || owner() == msg.sender, "Not an admin");
        _;
    }
    
    modifier onlyProducer() {
        require(isProducer[msg.sender], "Not an authorized producer");
        _;
    }
    
    modifier onlyReseller() {
        require(isReseller[msg.sender], "Not an authorized reseller");
        _;
    }
    
    modifier notBlacklisted() {
        require(!blacklistedHolders[msg.sender], "Account is blacklisted for abusive storage");
        _;

    }
    constructor() {
    _transferOwnership(msg.sender);
    isAdmin[msg.sender] = true;
    emit AdminAdded(msg.sender);
}

    
    function addAdmin(address account) external onlyAdmin {
        require(!isAdmin[account], "Address is already an admin");
        isAdmin[account] = true;
        emit AdminAdded(account);
    }
    
    function removeAdmin(address account) external onlyAdmin {
        require(isAdmin[account], "Address is not an admin");
        isAdmin[account] = false;
        emit AdminRemoved(account);
    }
    
    function setReseller(address account, uint256 maxQuantity) external onlyAdmin {
        require(!isReseller[account], "Address is already a reseller");
        require(!blacklistedHolders[account], "Address is blacklisted for abusive storage");
        totalResellers++;
        isReseller[account] = true;
        maxQuantityPerReseller[account] = maxQuantity;
        emit ResellerAdded(account);
    }
    
    function changeMaxQuantityReseller(address account, uint256 maxQuantity) external onlyAdmin {
        require(isReseller[account], "Address is not a reseller");
        maxQuantityPerReseller[account] = maxQuantity;
        emit ResellerChanged(account, msg.sender, maxQuantity, block.timestamp);
    }
    
    function removeReseller(address account) external onlyAdmin {
        require(isReseller[account], "Address is not a reseller");
        isReseller[account] = false;
        totalResellers--;
        emit ResellerRemoved(account);
    }
    
    function setProducer(address account) external onlyAdmin {
        require(!isProducer[account], "Address is already a producer");
        require(!blacklistedHolders[account], "Address is blacklisted for abusive storage");
        isProducer[account] = true;
        totalProducers++;
        emit ProducerAdded(account);
    }
    
    function removeProducer(address account) external onlyAdmin {
        require(isProducer[account], "Address is not a producer");
        isProducer[account] = false;
        totalProducers--;
        emit ProducerRemoved(account);
    }
    
    function setMaxStorageDuration(uint256 newDuration) external onlyAdmin {
        uint256 oldDuration = maxStorageDuration;
        maxStorageDuration = newDuration;
        emit MaxStorageDurationChanged(oldDuration, newDuration);
    }
    
    function setViolationThreshold(uint256 newThreshold) external onlyAdmin {
        require(newThreshold > 0, "Threshold must be greater than zero");
        uint256 oldThreshold = violationThreshold;
        violationThreshold = newThreshold;
        emit ViolationThresholdChanged(oldThreshold, newThreshold);
    }
    
    function produce(uint256 quantity) external onlyProducer notBlacklisted {
        uint256 batchId = nextBatchId++;
        batches[batchId] = Batch({
            id: batchId,
            producer: msg.sender,
            quantity: quantity,
            timestamp: block.timestamp,
            currentOwner: msg.sender,
            expired: false
        });
        
        stockBalance[msg.sender] +=  quantity;
        batchesByOwner[msg.sender].push(batchId);
        
        emit Produced(batchId, msg.sender, quantity, block.timestamp);
    }
    
    function transferStock(address to, uint256 amount, uint256 batchId) external notBlacklisted {
        require(stockBalance[msg.sender] >= amount, "Insufficient stock");
        require(isProducer[msg.sender] || isReseller[msg.sender], "Unauthorized transfer");
        require(isReseller[to], "Recipient not authorized");
        require(!blacklistedHolders[to], "Recipient is blacklisted for abusive storage");
        require(batches[batchId].currentOwner == msg.sender, "You don't own this batch");
        require(batches[batchId].quantity >= amount, "Insufficient quantity in batch");
        //check for quantity
        checkForQuantity(to,amount,batchId);
        
        // Check for abusive storage
        checkForAbusiveStorage(batchId);
        
        if (amount == batches[batchId].quantity) {
            // ken kad eli talbou kad fil batch aatih elbatch
            batches[batchId].currentOwner = to;
            removeBatchFromOwner(msg.sender, batchId);
            batchesByOwner[to].push(batchId);
        } else {
            // snn aamel batch jdid nafs eldonnee
            //quantite kad eli tablou
            uint256 newBatchId = nextBatchId++;
            batches[newBatchId] = Batch({
                id: newBatchId,
                producer: batches[batchId].producer,
                quantity: amount,
                timestamp: batches[batchId].timestamp, 
                currentOwner: to,
                expired: false
            });
            
            // mise ajour batch original
            batches[batchId].quantity -= amount;
            
            // aatih lil jdid
            batchesByOwner[to].push(newBatchId);
        }
        
        stockBalance[msg.sender] -= amount;
        stockBalance[to] += amount;
        
        emit Transferred(msg.sender, to, amount, batchId);
    }

    
    function checkForAbusiveStorage(uint256 batchId) public returns (bool) {
        Batch storage batch = batches[batchId];
        
        if (block.timestamp > batch.timestamp + maxStorageDuration) {
            // Report violation
            uint256 violationId = nextViolationId++;
            violations[violationId] = StorageViolation({
                violationType:ViolationType.ExcessiveStorage,
                holder: batch.currentOwner,
                batchId: batchId,
                detectionTime: block.timestamp,
                resolved: false
            });
            if(isProducer[batch.currentOwner]){
                totalProducers--;
            }
            if(isReseller[batch.currentOwner]){
                totalResellers--;
            }
            violationsByHolder[batch.currentOwner].push(violationId);
            
            emit AbusiveStorageDetected(violationId, batch.currentOwner, batchId, block.timestamp);
            
            // holder  blacklisted??
            if (violationsByHolder[batch.currentOwner].length >= violationThreshold) {
                blacklistedHolders[batch.currentOwner] = true;
                emit HolderBlacklisted(batch.currentOwner, violationsByHolder[batch.currentOwner].length);
            }
            
            return true;
        }
        
        return false;
    }
    
    function resolveViolation(uint256 violationId) external onlyAdmin {
        require(violationId < nextViolationId, "Violation does not exist");
        require(!violations[violationId].resolved, "Violation already resolved");
        
        violations[violationId].resolved = true;
        emit ViolationResolved(violationId, msg.sender);
    }
    
    function removeFromBlacklist(address holder) external onlyAdmin {
        require(blacklistedHolders[holder], "Address is not blacklisted");
        blacklistedHolders[holder] = false;
        emit HolderRemovedFromBlacklist(holder);
    }
    
    function checkAllBatchesForAbusiveStorage() external {
        uint256 violationCount = 0;
        
        for (uint256 i = 0; i < nextBatchId; i++) {
            if (batches[i].quantity > 0) {
                if (checkForAbusiveStorage(i)) {
                    violationCount++;
                }
            }
        }
        
        totalViolations=violationCount;
    }
    
    function getActiveViolationsByHolder(address holder) external view returns (uint256[] memory) {
        uint256[] storage allViolations = violationsByHolder[holder];
        uint256 activeCount = 0;
        
        // Count active violations
        for (uint256 i = 0; i < allViolations.length; i++) {
            if (!violations[allViolations[i]].resolved) {
                activeCount++;
            }
        }
        
        // Create result array
        uint256[] memory activeViolations = new uint256[](activeCount);
        uint256 index = 0;
        
        // Populate result array
        for (uint256 i = 0; i < allViolations.length; i++) {
            if (!violations[allViolations[i]].resolved) {
                activeViolations[index] = allViolations[i];
                index++;
            }
        }
        
        return activeViolations;
    }
    
    function getBatchesNearingViolation(uint256 daysThreshold) external view returns (uint256[] memory) {
        uint256 warningTime = maxStorageDuration - (daysThreshold * 1 days);
        uint256 count = 0;
        
        // Count qualifying batches
        for (uint256 i = 0; i < nextBatchId; i++) {
            if (batches[i].quantity > 0) {
                uint256 batchAge = block.timestamp - batches[i].timestamp;
                if (batchAge > warningTime && batchAge <= maxStorageDuration) {
                    count++;
                }
            }
        }
        
        // Create result array
        uint256[] memory warningBatches = new uint256[](count);
        uint256 index = 0;
        
        // Populate result array
        for (uint256 i = 0; i < nextBatchId; i++) {
            if (batches[i].quantity > 0) {
                uint256 batchAge = block.timestamp - batches[i].timestamp;
                if (batchAge > warningTime && batchAge <= maxStorageDuration) {
                    warningBatches[index] = i;
                    index++;
                }
            }
        }
        
        return warningBatches;
    }
    
    function getBatchesByOwner(address owner) external view returns (uint256[] memory) {
        return batchesByOwner[owner];
    }
    
    function removeBatchFromOwner(address owner, uint256 batchId) private {
        uint256[] storage ownerBatches = batchesByOwner[owner];
        for (uint256 i = 0; i < ownerBatches.length; i++) {
            if (ownerBatches[i] == batchId) {
                // Replace with last element and pop
                ownerBatches[i] = ownerBatches[ownerBatches.length - 1];
                ownerBatches.pop();
                break;
            }
        }
    }
    
    function isHolderViolatingStorageRules(address holder) external view returns (bool) {
        uint256[] storage holderViolations = violationsByHolder[holder];
        uint256 activeViolations = 0;
        
        for (uint256 i = 0; i < holderViolations.length; i++) {
            if (!violations[holderViolations[i]].resolved) {
                activeViolations++;
            }
        }
        
        return activeViolations > 0;
    }

    function getRole(address account) external view returns (string memory) {
        if (isAdmin[account]) return "admin";
        if (isProducer[account]) return "producer";
        if (isReseller[account]) return "reseller";
        return "unknown";
    }
    function setPosition(address account,uint256 latitude,uint256 longitude) external {
        require(isAdmin[msg.sender], "Address is not an admin");
        addressPosition[account].latitude=latitude;
        addressPosition[account].longitude=longitude;
    }
    function setName(address account, string memory name)public {
        require(isAdmin[msg.sender], "Address is not an admin");
        addressName[account]=name;
    }
    function triggerFakeViolation(address holder, uint256 batchId, ViolationType vType) external onlyAdmin {
    uint256 violationId = nextViolationId++;
    violations[violationId] = StorageViolation({
        violationType: vType,
        holder: holder,
        batchId: batchId,
        detectionTime: block.timestamp,
        resolved: false
    });

    violationsByHolder[holder].push(violationId);

    emit AbusiveStorageDetected(violationId, holder, batchId, block.timestamp);

    if (violationsByHolder[holder].length >= violationThreshold && !blacklistedHolders[holder]) {
        blacklistedHolders[holder] = true;
        emit HolderBlacklisted(holder, violationsByHolder[holder].length);
    }
}
function checkForQuantity(address to,uint256 amount,uint256 batchId) public{
        Batch storage batch = batches[batchId];
        if (stockBalance[to]+amount>maxQuantityPerReseller[to]){
            uint256 violationId = nextViolationId++;
            violations[violationId] = StorageViolation({
                violationType: ViolationType.QuantityOverflow,
                holder: batch.currentOwner,
                batchId: batchId,
                detectionTime: block.timestamp,
                resolved: false
            });
            
            violationsByHolder[batch.currentOwner].push(violationId);
            
            emit AbusiveStorageDetected(violationId, batch.currentOwner, batchId, block.timestamp);
            
            // holder  blacklisted??
            if (violationsByHolder[batch.currentOwner].length >= violationThreshold) {
                blacklistedHolders[batch.currentOwner] = true;
                emit HolderBlacklisted(batch.currentOwner, violationsByHolder[batch.currentOwner].length);
                revert("Recipient exceeds maximum allowed stock");
        }
        }}

 function blacklistManually(address holder) external onlyAdmin {
    require(!blacklistedHolders[holder], "Already blacklisted");
    blacklistedHolders[holder] = true;
    emit HolderBlacklisted(holder, violationsByHolder[holder].length);
}

}