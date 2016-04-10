-- phpMyAdmin SQL Dump
-- version 2.10.3
-- http://www.phpmyadmin.net
-- 
-- Host: localhost
-- Generation Time: Apr 11, 2008 at 08:33 PM
-- Server version: 5.0.45
-- PHP Version: 5.2.3

SET SQL_MODE="NO_AUTO_VALUE_ON_ZERO";

-- 
-- Database: `pushfour`
-- 

-- --------------------------------------------------------

-- 
-- Table structure for table `tblboards`
-- 

CREATE TABLE `tblboards` (
  `xSize` tinyint(3) unsigned NOT NULL,
  `ySize` tinyint(3) unsigned NOT NULL,
  `boardID` int(10) unsigned NOT NULL auto_increment,
  `layout` varchar(255) collate latin1_general_ci NOT NULL,
  PRIMARY KEY  (`boardID`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_general_ci AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

-- 
-- Table structure for table `tblcolors`
-- 

CREATE TABLE `tblcolors` (
  `colorID` tinyint(3) unsigned NOT NULL auto_increment,
  `colorHex` varchar(6) collate latin1_general_ci NOT NULL default 'FF0000',
  PRIMARY KEY  (`colorID`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_general_ci AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

-- 
-- Table structure for table `tblgames`
-- 

CREATE TABLE `tblgames` (
  `gameID` int(10) unsigned NOT NULL auto_increment,
  `playerID` int(10) unsigned NOT NULL,
  `colorID` tinyint(4) NOT NULL,
  `orderNumber` tinyint(3) unsigned NOT NULL default '1',
  `gameStatus` tinyint(3) unsigned NOT NULL default '0',
  UNIQUE KEY `gameID` (`gameID`,`playerID`,`colorID`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_general_ci AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

-- 
-- Table structure for table `tblgamestatus`
-- 

CREATE TABLE `tblgamestatus` (
  `statusID` tinyint(3) unsigned NOT NULL,
  `statusMessage` varchar(255) collate latin1_general_ci NOT NULL,
  PRIMARY KEY  (`statusID`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_general_ci;

-- --------------------------------------------------------

-- 
-- Table structure for table `tblmoves`
-- 

CREATE TABLE `tblmoves` (
  `gameID` int(10) unsigned NOT NULL,
  `moveNumber` tinyint(3) unsigned NOT NULL auto_increment COMMENT 'increase with max allowable board size',
  `colorID` tinyint(4) unsigned NOT NULL,
  `playerID` int(11) unsigned NOT NULL,
  UNIQUE KEY `gameID` (`gameID`,`moveNumber`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_general_ci AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

-- 
-- Table structure for table `tblplayers`
-- 

CREATE TABLE `tblplayers` (
  `name` varchar(40) collate latin1_general_ci NOT NULL,
  `playerID` int(10) unsigned NOT NULL auto_increment,
  PRIMARY KEY  (`playerID`),
  UNIQUE KEY `name` (`name`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_general_ci AUTO_INCREMENT=1 ;
