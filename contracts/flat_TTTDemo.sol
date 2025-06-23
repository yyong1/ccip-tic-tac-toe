// Sources flattened with hardhat v2.24.0 https://hardhat.org

// SPDX-License-Identifier: BUSL-1.1 AND MIT

// File cross-not-official/contracts/libraries/Client.sol@v1.0.0

// Original license: SPDX_License_Identifier: BUSL-1.1
pragma solidity ^0.8.0;

// End consumer library.
library Client {
  struct EVMTokenAmount {
    address token; // token address on the local chain.
    uint256 amount; // Amount of tokens.
  }

  struct Any2EVMMessage {
    bytes32 messageId; // MessageId corresponding to ccipSend on source.
    uint64 sourceChainSelector; // Source chain selector.
    bytes sender; // abi.decode(sender) if coming from an EVM chain.
    bytes data; // payload sent in original message.
    EVMTokenAmount[] destTokenAmounts; // Tokens and their amounts in their destination chain representation.
  }

  // If extraArgs is empty bytes, the default is 200k gas limit and strict = false.
  struct EVM2AnyMessage {
    bytes receiver; // abi.encode(receiver address) for dest EVM chains
    bytes data; // Data payload
    EVMTokenAmount[] tokenAmounts; // Token transfers
    address feeToken; // Address of feeToken. address(0) means you will send msg.value.
    bytes extraArgs; // Populate this with _argsToBytes(EVMExtraArgsV1)
  }

  // extraArgs will evolve to support new features
  // bytes4(keccak256("CCIP EVMExtraArgsV1"));
  bytes4 public constant EVM_EXTRA_ARGS_V1_TAG = 0x97a657c9;
  struct EVMExtraArgsV1 {
    uint256 gasLimit;
    bool strict; // See strict sequencing details below.
  }

  function _argsToBytes(EVMExtraArgsV1 memory extraArgs) internal pure returns (bytes memory bts) {
    return abi.encodeWithSelector(EVM_EXTRA_ARGS_V1_TAG, extraArgs);
  }
}


// File cross-not-official/contracts/interfaces/IAny2EVMMessageReceiver.sol@v1.0.0

// Original license: SPDX_License_Identifier: BUSL-1.1
pragma solidity ^0.8.0;

/// @notice Application contracts that intend to receive messages from
/// the router should implement this interface.
interface IAny2EVMMessageReceiver {
  /// @notice Called by the Router to deliver a message.
  /// If this reverts, any token transfers also revert. The message
  /// will move to a FAILED state and become available for manual execution.
  /// @param message CCIP Message
  /// @dev Note ensure you check the msg.sender is the OffRampRouter
  function ccipReceive(Client.Any2EVMMessage calldata message) external;
}


// File cross-not-official/vendor/openzeppelin-solidity/v4.8.0/utils/introspection/IERC165.sol@v1.0.0

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
  /**
    * @dev Returns true if this contract implements the interface defined by
    * `interfaceId`. See the corresponding
    * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
    * to learn more about how these ids are created.
    *
    * This function call must use less than 30 000 gas.
    */
  function supportsInterface(bytes4 interfaceId) external view returns (bool);
}


// File cross-not-official/contracts/applications/CCIPReceiver.sol@v1.0.0

// Original license: SPDX_License_Identifier: BUSL-1.1
pragma solidity 0.8.19;

/// @title CCIPReceiver - Base contract for CCIP applications that can receive messages.
abstract contract CCIPReceiver is IAny2EVMMessageReceiver, IERC165 {
  address private immutable i_router;

  constructor(address router) {
    if (router == address(0)) revert InvalidRouter(address(0));
    i_router = router;
  }

  /// @notice IERC165 supports an interfaceId
  /// @param interfaceId The interfaceId to check
  /// @return true if the interfaceId is supported
  function supportsInterface(bytes4 interfaceId) public pure override returns (bool) {
    return interfaceId == type(IAny2EVMMessageReceiver).interfaceId || interfaceId == type(IERC165).interfaceId;
  }

  /// @inheritdoc IAny2EVMMessageReceiver
  function ccipReceive(Client.Any2EVMMessage calldata message) external override onlyRouter {
    _ccipReceive(message);
  }

  /// @notice Override this function in your implementation.
  /// @param message Any2EVMMessage
  function _ccipReceive(Client.Any2EVMMessage memory message) internal virtual;

  /////////////////////////////////////////////////////////////////////
  // Plumbing
  /////////////////////////////////////////////////////////////////////

  /// @notice Return the current router
  /// @return i_router address
  function getRouter() public view returns (address) {
    return address(i_router);
  }

  error InvalidRouter(address router);

  /// @dev only calls from the set router are accepted.
  modifier onlyRouter() {
    if (msg.sender != address(i_router)) revert InvalidRouter(msg.sender);
    _;
  }
}


// File cross-not-official/contracts/interfaces/IRouterClient.sol@v1.0.0

// Original license: SPDX_License_Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IRouterClient {
  error UnsupportedDestinationChain(uint64 destChainSelector);
  error InsufficientFeeTokenAmount();
  error InvalidMsgValue();

  /// @notice Checks if the given chain ID is supported for sending/receiving.
  /// @param chainSelector The chain to check.
  /// @return supported is true if it is supported, false if not.
  function isChainSupported(uint64 chainSelector) external view returns (bool supported);

  /// @notice Gets a list of all supported tokens which can be sent or received
  /// to/from a given chain id.
  /// @param chainSelector The chainSelector.
  /// @return tokens The addresses of all tokens that are supported.
  function getSupportedTokens(uint64 chainSelector) external view returns (address[] memory tokens);

  /// @param destinationChainSelector The destination chainSelector
  /// @param message The cross-chain CCIP message including data and/or tokens
  /// @return fee returns guaranteed execution fee for the specified message
  /// delivery to destination chain
  /// @dev returns 0 fee on invalid message.
  function getFee(
    uint64 destinationChainSelector,
    Client.EVM2AnyMessage memory message
  ) external view returns (uint256 fee);

  /// @notice Request a message to be sent to the destination chain
  /// @param destinationChainSelector The destination chain ID
  /// @param message The cross-chain CCIP message including data and/or tokens
  /// @return messageId The message ID
  /// @dev Note if msg.value is larger than the required fee (from getFee) we accept
  /// the overpayment with no refund.
  function ccipSend(
    uint64 destinationChainSelector,
    Client.EVM2AnyMessage calldata message
  ) external payable returns (bytes32);
}


// File cross-not-official/libraries/internal/interfaces/OwnableInterface.sol@v1.0.0

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.0;

interface OwnableInterface {
  function owner() external returns (address);

  function transferOwnership(address recipient) external;

  function acceptOwnership() external;
}


// File cross-not-official/libraries/internal/ConfirmedOwnerWithProposal.sol@v1.0.0

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwnerWithProposal is OwnableInterface {
  address private s_owner;
  address private s_pendingOwner;

  event OwnershipTransferRequested(address indexed from, address indexed to);
  event OwnershipTransferred(address indexed from, address indexed to);

  constructor(address newOwner, address pendingOwner) {
    require(newOwner != address(0), "Cannot set owner to zero");

    s_owner = newOwner;
    if (pendingOwner != address(0)) {
      _transferOwnership(pendingOwner);
    }
  }

  /**
   * @notice Allows an owner to begin transferring ownership to a new address,
   * pending.
   */
  function transferOwnership(address to) public override onlyOwner {
    _transferOwnership(to);
  }

  /**
   * @notice Allows an ownership transfer to be completed by the recipient.
   */
  function acceptOwnership() external override {
    require(msg.sender == s_pendingOwner, "Must be proposed owner");

    address oldOwner = s_owner;
    s_owner = msg.sender;
    s_pendingOwner = address(0);

    emit OwnershipTransferred(oldOwner, msg.sender);
  }

  /**
   * @notice Get the current owner
   */
  function owner() public view override returns (address) {
    return s_owner;
  }

  /**
   * @notice validate, transfer ownership, and emit relevant events
   */
  function _transferOwnership(address to) private {
    require(to != msg.sender, "Cannot transfer to self");

    s_pendingOwner = to;

    emit OwnershipTransferRequested(s_owner, to);
  }

  /**
   * @notice validate access
   */
  function _validateOwnership() internal view {
    require(msg.sender == s_owner, "Only callable by owner");
  }

  /**
   * @notice Reverts if called by anyone other than the contract owner.
   */
  modifier onlyOwner() {
    _validateOwnership();
    _;
  }
}


// File cross-not-official/libraries/internal/ConfirmedOwner.sol@v1.0.0

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwner is ConfirmedOwnerWithProposal {
  constructor(address newOwner) ConfirmedOwnerWithProposal(newOwner, address(0)) {}
}


// File cross-not-official/contracts/OwnerIsCreator.sol@v1.0.0

// Original license: SPDX_License_Identifier: BUSL-1.1
pragma solidity ^0.8.0;

/// @title The OwnerIsCreator contract
/// @notice A contract with helpers for basic contract ownership.
contract OwnerIsCreator is ConfirmedOwner {
  constructor() ConfirmedOwner(msg.sender) {}
}


// File cross-not-official/vendor/openzeppelin-solidity/v4.8.0/token/ERC20/IERC20.sol@v1.0.0

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
  /**
   * @dev Emitted when `value` tokens are moved from one account (`from`) to
   * another (`to`).
   *
   * Note that `value` may be zero.
   */
  event Transfer(address indexed from, address indexed to, uint256 value);

  /**
   * @dev Emitted when the allowance of a `spender` for an `owner` is set by
   * a call to {approve}. `value` is the new allowance.
   */
  event Approval(address indexed owner, address indexed spender, uint256 value);

  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the amount of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint256);

  /**
   * @dev Moves `amount` tokens from the caller's account to `to`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address to, uint256 amount) external returns (bool);

  /**
   * @dev Returns the remaining number of tokens that `spender` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This value changes when {approve} or {transferFrom} are called.
   */
  function allowance(address owner, address spender) external view returns (uint256);

  /**
   * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * IMPORTANT: Beware that changing an allowance with this method brings the risk
   * that someone may use both the old and the new allowance by unfortunate
   * transaction ordering. One possible solution to mitigate this race
   * condition is to first reduce the spender's allowance to 0 and set the
   * desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   *
   * Emits an {Approval} event.
   */
  function approve(address spender, uint256 amount) external returns (bool);

  /**
   * @dev Moves `amount` tokens from `from` to `to` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(
    address from,
    address to,
    uint256 amount
  ) external returns (bool);
}


// File contracts/TTTDemo.sol

// Original license: SPDX_License_Identifier: MIT
pragma solidity 0.8.19;





/**
 * THIS IS AN EXAMPLE CONTRACT THAT USES HARDCODED VALUES FOR CLARITY.
 * THIS IS AN EXAMPLE CONTRACT THAT USES UN-AUDITED CODE.
 * DO NOT USE THIS CODE IN PRODUCTION.
 */

/// @title - A simple messenger contract for sending/receiving string messages across chains.
/// Pay using native tokens (e.g, ETH in Ethereum)
contract TTTDemo is CCIPReceiver, OwnerIsCreator {
    // Custom errors to provide more descriptive revert messages.
    error NoMessageReceived(); // Used when trying to access a message but no messages have been received.
    error IndexOutOfBound(uint256 providedIndex, uint256 maxIndex); // Used when the provided index is out of bounds.
    error MessageIdNotExist(bytes32 messageId); // Used when the provided message ID does not exist.
    error NothingToWithdraw(); // Used when trying to withdraw Ether but there's nothing to withdraw.
    error FailedToWithdrawEth(address owner, address target, uint256 value); // Used when the withdrawal of Ether fails.

    struct GameSession {
        bytes32 sessionId;
        address player_1; // player who starts the game
        address player_2; // the other player in the game
        address winner; // winner of game
        address turn; // check who takes action in next step
        uint8[9] player1Status; // current status for player 1
        uint8[9] player2Status; // current status for player 2
    }
    mapping(bytes32 => GameSession) public gameSessions;
    bytes32[] public sessionIds;

    uint8[9] initialCombination = [0, 0, 0, 0, 0, 0, 0, 0, 0];

    function getPlayer1Status(
        bytes32 _sessionId
    ) external view returns (uint8[9] memory) {
        return gameSessions[_sessionId].player1Status;
    }

    function getPlayer2Status(
        bytes32 _sessionId
    ) external view returns (uint8[9] memory) {
        return gameSessions[_sessionId].player2Status;
    }

    // Event emitted when a message is sent to another chain.
    event MessageSent(
        bytes32 indexed messageId, // The unique ID of the message.
        uint64 indexed destinationChainSelector, // The chain selector of the destination chain.
        address receiver, // The address of the receiver on the destination chain.
        GameSession message, // The message being sent.
        uint256 fees // The fees paid for sending the message.
    );

    // Event emitted when a message is received from another chain.
    event MessageReceived(
        bytes32 indexed messageId, // The unique ID of the message.
        uint64 indexed sourceChainSelector, // The chain selector of the source chain.
        address sender, // The address of the sender from the source chain.
        GameSession message // The message that was received.
    );

    // Struct to hold details of a message.
    struct Message {
        uint64 sourceChainSelector; // The chain selector of the source chain.
        address sender; // The address of the sender.
        GameSession message; // The content of the message.
    }

    // Storage variables.
    bytes32[] public receivedMessages; // Array to keep track of the IDs of received messages.
    mapping(bytes32 => Message) public messageDetail; // Mapping from message ID to Message struct, storing details of each received message.
    address public _router;

    /// @notice Constructor initializes the contract with the router address.
    /// @param router The address of the router contract.
    constructor(address router) CCIPReceiver(router) {}

    function updateRouter(address routerAddr) external {
        _router = routerAddr;
    }

    function start(uint64 destinationChainSelector, address receiver) external {
        bytes32 uniqueId = keccak256(
            abi.encodePacked(block.timestamp, msg.sender)
        );
        sessionIds.push(uniqueId);
        gameSessions[uniqueId] = GameSession(
            uniqueId,
            msg.sender,
            address(0),
            address(0),
            msg.sender,
            initialCombination,
            initialCombination
        );

        sendMessage(destinationChainSelector, receiver, gameSessions[uniqueId]);
    }

    function checkWin(
        uint8[9] memory playerStatus
    ) public pure returns (bool _return) {
        if (
            horizontalCheck(playerStatus) ||
            verticalCheck(playerStatus) ||
            diagonalCheck(playerStatus)
        ) {
            return true;
        }

        return false;
    }

    /// @notice Sends data to receiver on the destination chain.
    /// @dev Assumes your contract has sufficient native asset (e.g, ETH on Ethereum, MATIC on Polygon...).
    /// @param destinationChainSelector The identifier (aka selector) for the destination blockchain.
    /// @param receiver The address of the recipient on the destination blockchain.
    /// @param message The string message to be sent.
    /// @return messageId The ID of the message that was sent.
    function sendMessage(
        uint64 destinationChainSelector,
        address receiver,
        GameSession memory message
    ) public returns (bytes32 messageId) {
        // Create an EVM2AnyMessage struct in memory with necessary information for sending a cross-chain message
        Client.EVM2AnyMessage memory evm2AnyMessage = Client.EVM2AnyMessage({
            receiver: abi.encode(receiver), // ABI-encoded receiver address
            data: abi.encode(message), // ABI-encoded string message
            tokenAmounts: new Client.EVMTokenAmount[](0), // Empty array indicating no tokens are being sent
            extraArgs: Client._argsToBytes(
                Client.EVMExtraArgsV1({gasLimit: 400_000, strict: false}) // Additional arguments, setting gas limit and non-strict sequency mode
            ),
            feeToken: address(0) // Setting feeToken to zero address, indicating native asset will be used for fees
        });

        // Initialize a router client instance to interact with cross-chain router
        IRouterClient router = IRouterClient(_router);

        // Get the fee required to send the message
        uint256 fees = router.getFee(destinationChainSelector, evm2AnyMessage);

        // Send the message through the router and store the returned message ID
        messageId = router.ccipSend{value: fees}(
            destinationChainSelector,
            evm2AnyMessage
        );

        // Emit an event with message details
        emit MessageSent(
            messageId,
            destinationChainSelector,
            receiver,
            message,
            fees
        );

        // Return the message ID
        return messageId;
    }

    // check if the position is taken then move
    function move(
        uint256 x,
        uint256 y,
        uint256 player,
        bytes32 sessionId,
        uint64 destinationChainSelector,
        address receiver
    ) public {
        GameSession memory gs = gameSessions[sessionId];
        // make sure the game session setup and not over.
        require(
            gs.player_1 != address(0),
            "the session is not setup, please start game first!"
        );
        require(gs.winner == address(0), "the game is over");

        // make sure the player is in the game session
        require(player == 1 || player == 2, "you must be player1 or player2"); //this is used to when player has the same address

        if (player == 1) {
            // make sure it is player1's turn to move
            require(
                gs.player_1 == msg.sender && gs.turn == msg.sender,
                "it is not your turn"
            );

            // 1. if the position is not taken by the oppenent, then take the position
            if (
                gs.player1Status[x * 3 + y] == 0 &&
                gs.player2Status[x * 3 + y] == 0
            ) {
                gameSessions[sessionId].player1Status[x * 3 + y] = 1;

                // 2. check if player1 wins or make the turn to the opponent, send the message
                if (checkWin(gameSessions[sessionId].player1Status)) {
                    gameSessions[sessionId].winner = gameSessions[sessionId]
                        .player_1;
                } else {
                    gameSessions[sessionId].turn = gameSessions[sessionId]
                        .player_2;
                }
                sendMessage(
                    destinationChainSelector,
                    receiver,
                    gameSessions[sessionId]
                );
            } else {
                revert("the position is occupied");
            }
        } else if (player == 2) {
            // make sure it is player2's turn to move, this is the first step for player2
            require(
                (gs.player_2 == msg.sender && gs.turn == msg.sender) ||
                    gs.player_2 == address(0),
                "it is not your turn"
            );

            if (gs.player_2 == address(0)) {
                gameSessions[sessionId].player_2 = msg.sender;
            }

            // 1. if the position is not taken by the oppenent, then take the position
            if (
                gs.player1Status[x * 3 + y] == 0 &&
                gs.player2Status[x * 3 + y] == 0
            ) {
                gameSessions[sessionId].player2Status[x * 3 + y] = 1;

                // 2. check if player1 wins or make the turn to the oppenent, send the message
                if (checkWin(gameSessions[sessionId].player2Status)) {
                    gameSessions[sessionId].winner = gameSessions[sessionId]
                        .player_2;
                } else {
                    gameSessions[sessionId].turn = gameSessions[sessionId]
                        .player_1;
                }
                sendMessage(
                    destinationChainSelector,
                    receiver,
                    gameSessions[sessionId]
                );
            } else {
                revert("the position is occupied");
            }
        }
    }

    /// handle a received message
    function _ccipReceive(
        Client.Any2EVMMessage memory any2EvmMessage
    ) internal override {
        bytes32 messageId = any2EvmMessage.messageId; // fetch the messageId
        uint64 sourceChainSelector = any2EvmMessage.sourceChainSelector; // fetch the source chain identifier (aka selector)
        address sender = abi.decode(any2EvmMessage.sender, (address)); // abi-decoding of the sender address
        GameSession memory message = abi.decode(
            any2EvmMessage.data,
            (GameSession)
        ); // abi-decoding of the sent string message
        receivedMessages.push(messageId);
        Message memory detail = Message(sourceChainSelector, sender, message);
        messageDetail[messageId] = detail;
        gameSessions[message.sessionId] = message;
        sessionIds.push(message.sessionId);

        emit MessageReceived(messageId, sourceChainSelector, sender, message);
    }

    /// @notice Get the total number of received messages.
    /// @return number The total number of received messages.
    function getNumberOfReceivedMessages()
        external
        view
        returns (uint256 number)
    {
        return receivedMessages.length;
    }

    /// @notice Fetches the details of the last received message.
    /// @dev Reverts if no messages have been received yet.
    /// @return messageId The ID of the last received message.
    /// @return sourceChainSelector The source chain identifier (aka selector) of the last received message.
    /// @return sender The address of the sender of the last received message.
    /// @return message The last received message.
    function getLastReceivedMessageDetails()
        external
        view
        returns (
            bytes32 messageId,
            uint64 sourceChainSelector,
            address sender,
            GameSession memory message
        )
    {
        // Revert if no messages have been received
        if (receivedMessages.length == 0) revert NoMessageReceived();

        // Fetch the last received message ID
        messageId = receivedMessages[receivedMessages.length - 1];

        // Fetch the details of the last received message
        Message memory detail = messageDetail[messageId];

        return (
            messageId,
            detail.sourceChainSelector,
            detail.sender,
            detail.message
        );
    }

    function horizontalCheck(
        uint8[9] memory playerStatus
    ) private pure returns (bool horizontalValidation) {
        if (
            playerStatus[0] == 1 && playerStatus[1] == 1 && playerStatus[2] == 1
        ) {
            return true;
        }

        if (
            playerStatus[3] == 1 && playerStatus[4] == 1 && playerStatus[5] == 1
        ) {
            return true;
        }

        if (
            playerStatus[6] == 1 && playerStatus[7] == 1 && playerStatus[8] == 1
        ) {
            return true;
        }

        return false;
    }

    function verticalCheck(
        uint8[9] memory playerStatus
    ) private pure returns (bool verticalValidation) {
        if (
            playerStatus[0] == 1 && playerStatus[3] == 1 && playerStatus[6] == 1
        ) {
            return true;
        }

        if (
            playerStatus[1] == 1 && playerStatus[4] == 1 && playerStatus[7] == 1
        ) {
            return true;
        }

        if (
            playerStatus[2] == 1 && playerStatus[5] == 1 && playerStatus[8] == 1
        ) {
            return true;
        }

        return false;
    }

    function diagonalCheck(
        uint8[9] memory playerStatus
    ) private pure returns (bool diagonalValidation) {
        if (
            playerStatus[0] == 1 && playerStatus[4] == 1 && playerStatus[8] == 1
        ) {
            return true;
        }

        if (
            playerStatus[2] == 1 && playerStatus[4] == 1 && playerStatus[6] == 1
        ) {
            return true;
        }

        return false;
    }

    /// @notice Fallback function to allow the contract to receive Ether.
    /// @dev This function has no function body, making it a default function for receiving Ether.
    /// It is automatically called when Ether is sent to the contract without any data.
    receive() external payable {}

    /// @notice Allows the contract owner to withdraw the entire balance of Ether from the contract.
    /// @dev This function reverts if there are no funds to withdraw or if the transfer fails.
    /// It should only be callable by the owner of the contract.
    /// @param beneficiary The address to which the Ether should be sent.
    function withdraw(address beneficiary) public onlyOwner {
        // Retrieve the balance of this contract
        uint256 amount = address(this).balance;

        // Revert if there is nothing to withdraw
        if (amount == 0) revert NothingToWithdraw();

        // Attempt to send the funds, capturing the success status and discarding any return data
        (bool sent, ) = beneficiary.call{value: amount}("");

        // Revert if the send failed, with information about the attempted transfer
        if (!sent) revert FailedToWithdrawEth(msg.sender, beneficiary, amount);
    }

    /// @notice Return the list of all active session IDs
    function getActiveSessions() external view returns (bytes32[] memory) {
        return sessionIds;
    }

    /// @notice Return the current board as a single array of 9 slots:
    ///         0 = empty, 1 = player1, 2 = player2
    function getBoardStatus(
        bytes32 _sessionId
    ) external view returns (uint8[9] memory board) {
        GameSession storage gs = gameSessions[_sessionId];

        for (uint256 i = 0; i < 9; i++) {
            if (gs.player1Status[i] == 1) {
                board[i] = 1;
            } else if (gs.player2Status[i] == 1) {
                board[i] = 2;
            } else {
                board[i] = 0;
            }
        }
    }
}
