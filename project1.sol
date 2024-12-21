// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract ProofOfAttendanceNFT is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    struct Event {
        string name;
        uint256 date;
        bool isActive;
        string baseURI;
        mapping(address => bool) hasAttended;
    }

    mapping(bytes32 => Event) public events;
    mapping(uint256 => bytes32) public tokenEvent;

    event EventCreated(bytes32 indexed eventId, string name, uint256 date);
    event AttendanceMarked(bytes32 indexed eventId, address indexed attendee, uint256 tokenId);
    event EventClosed(bytes32 indexed eventId);

    // Updated constructor to pass the initial owner address to Ownable
    constructor() ERC721("Proof of Attendance NFT", "POAP") Ownable(msg.sender) {}

    function createEvent(
        string memory name,
        uint256 date,
        string memory baseURI
    ) public onlyOwner returns (bytes32) {
        require(date >= block.timestamp, "Event date must be in the future");
        
        bytes32 eventId = keccak256(abi.encodePacked(name, date, block.timestamp));
        Event storage newEvent = events[eventId];
        newEvent.name = name;
        newEvent.date = date;
        newEvent.isActive = true;
        newEvent.baseURI = baseURI;

        emit EventCreated(eventId, name, date);
        return eventId;
    }

    function markAttendance(bytes32 eventId, address attendee) public onlyOwner {
        Event storage evt = events[eventId];
        require(evt.isActive, "Event is not active");
        require(block.timestamp >= evt.date, "Event hasn't started yet");
        require(!evt.hasAttended[attendee], "Attendee already has an NFT for this event");

        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();

        _safeMint(attendee, newTokenId);
        _setTokenURI(newTokenId, evt.baseURI);
        
        evt.hasAttended[attendee] = true;
        tokenEvent[newTokenId] = eventId;

        emit AttendanceMarked(eventId, attendee, newTokenId);
    }

    function closeEvent(bytes32 eventId) public onlyOwner {
        require(events[eventId].isActive, "Event is not active");
        events[eventId].isActive = false;
        emit EventClosed(eventId);
    }

    function hasAttendedEvent(bytes32 eventId, address attendee) public view returns (bool) {
        return events[eventId].hasAttended[attendee];
    }

    function getEventDetails(bytes32 eventId) public view returns (
        string memory name,
        uint256 date,
        bool isActive,
        string memory baseURI
    ) {
        Event storage evt = events[eventId];
        return (evt.name, evt.date, evt.isActive, evt.baseURI);
    }

    function batchMarkAttendance(bytes32 eventId, address[] calldata attendees) public onlyOwner {
        for (uint i = 0; i < attendees.length; i++) {
            if (!events[eventId].hasAttended[attendees[i]]) {
                markAttendance(eventId, attendees[i]);
            }
        }
    }
}