-- Cleaning Data with SQL queries:

SELECT *
FROM PortofolioProject.dbo.NashvilleHousing



-- 1) Standardize Date Format:

SELECT SaleDateConverted, CONVERT(date,SaleDate)
FROM PortofolioProject.dbo.NashvilleHousing

ALTER TABLE NashvilleHousing
ADD SaleDateConverted Date

UPDATE NashvilleHousing
SET SaleDateConverted = CONVERT(date,SaleDate)



--2) Populate Property Address data
--Find if the are nulls 
SELECT PropertyAddress
FROM PortofolioProject.dbo.NashvilleHousing
WHERE PropertyAddress is null

--Filling the nulls:
SELECT ParcelID, PropertyAddress
FROM PortofolioProject.dbo.NashvilleHousing
ORDER BY ParcelID

--NOTE : As we can see , when ParcelID is repetead so does the PropertyAddress. So we can assume that these ParcelIDs represent the PropertyAddresses.
--All we need to do right now is to check if these ParcelIDs with null PropertyAddresses appear somewhere else in the table, in order to take the address
--information from there and fill the nulls.


--Self-joining the table to find the above simularities and fill the nulls :

SELECT Table1.ParcelID,Table1.PropertyAddress,Table2.ParcelID,Table2.PropertyAddress, ISNULL(Table1.PropertyAddress,Table2.PropertyAddress)
FROM PortofolioProject.dbo.NashvilleHousing AS Table1
JOIN PortofolioProject.dbo.NashvilleHousing AS Table2
	ON Table1.ParcelID = Table2.ParcelID
	AND Table1.[UniqueID ] <> Table2.[UniqueID ]
WHERE Table1.PropertyAddress is null


UPDATE Table1
SET PropertyAddress = ISNULL(Table1.PropertyAddress,Table2.PropertyAddress)
FROM PortofolioProject.dbo.NashvilleHousing AS Table1
JOIN PortofolioProject.dbo.NashvilleHousing AS Table2
	ON Table1.ParcelID = Table2.ParcelID
	AND Table1.[UniqueID ] <> Table2.[UniqueID ]
WHERE Table1.PropertyAddress is null



--3) Breaking out Address into Indivitual Columns (Address,City,State)

SELECT PropertyAddress
FROM PortofolioProject.dbo.NashvilleHousing

-- By running the above query we can see that there is a comma. So we will start breaking out the address in two parts.
-- The first one will be from the beggining of the string untill the comma and the second one from the comma to the end.

SELECT
SUBSTRING(PropertyAddress, 1 ,CHARINDEX(',',PropertyAddress) -1) AS Address
,SUBSTRING(PropertyAddress , CHARINDEX(',',PropertyAddress) +1, LEN(PropertyAddress)) AS Address
FROM PortofolioProject.dbo.NashvilleHousing

-- Now we are going to create 2 new columns to add the new addresses into the table.

ALTER TABLE PortofolioProject.dbo.NashvilleHousing
ADD PropertySplitAddress Nvarchar(255)

UPDATE PortofolioProject.dbo.NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1 ,CHARINDEX(',',PropertyAddress) -1)

ALTER TABLE PortofolioProject.dbo.NashvilleHousing
ADD PropertyCity Nvarchar(255)

UPDATE PortofolioProject.dbo.NashvilleHousing
SET PropertyCity = SUBSTRING(PropertyAddress , CHARINDEX(',',PropertyAddress) +1, LEN(PropertyAddress))

SELECT PropertySplitAddress , PropertyCity
FROM PortofolioProject.dbo.NashvilleHousing


-- Now we need to do the same thing with Owner Address which has the address, the city and state in one column.
-- This time though we are not gonna use SUBSTRINGS , but instead we will use PARSENAME.

SELECT OwnerAddress
FROM PortofolioProject.dbo.NashvilleHousing


-- Before we start using the PARSENAME , we can see that our data in the column are separated by a comma(,) and not a period(.).
-- So we have to nest a replace function within our PARSENAME to change the commas with periods.

SELECT
PARSENAME(REPLACE(OwnerAddress, ',','.') ,3)
,PARSENAME(REPLACE(OwnerAddress, ',','.') ,2)
,PARSENAME(REPLACE(OwnerAddress, ',','.') ,1)
FROM PortofolioProject.dbo.NashvilleHousing

-- Again we are going to create 3 new columns to add the new owner's addresses into the table.

ALTER TABLE PortofolioProject.dbo.NashvilleHousing
ADD OwnerSplitAddress Nvarchar(255)

UPDATE PortofolioProject.dbo.NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',','.') ,3)

ALTER TABLE PortofolioProject.dbo.NashvilleHousing
ADD OwnerSplitCity Nvarchar(255)

UPDATE PortofolioProject.dbo.NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',','.') ,2)

ALTER TABLE PortofolioProject.dbo.NashvilleHousing
ADD OwnerSplitState Nvarchar(255)

UPDATE PortofolioProject.dbo.NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',','.') ,1)

SELECT OwnerSplitAddress, OwnerSplitCity , OwnerSplitState
FROM PortofolioProject.dbo.NashvilleHousing


--4) Fixing the column SoldAsVacant. As we  can see below this column has ('N' , 'No' , 'Y' , 'Yes'). 
-- Since most of the values are expressed like 'Yes' and 'No' we will change the rest to be like these two categories.

SELECT DISTINCT(SoldAsVacant) , COUNT(SoldAsVacant)
FROM PortofolioProject.dbo.NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY Count(SoldAsVacant)

-- Using CASE statement to make the changes

SELECT SoldAsVacant,
CASE
	WHEN SoldAsVacant = 'Y' THEN  'Yes'
	WHEN SoldAsVacant = 'N' THEN  'No'
	ELSE SoldAsVacant
END
FROM PortofolioProject.dbo.NashvilleHousing

-- Updating the SoldAsVacant column with our CASE statement

UPDATE PortofolioProject.dbo.NashvilleHousing
SET  SoldAsVacant = CASE
	WHEN SoldAsVacant = 'Y' THEN  'Yes'
	WHEN SoldAsVacant = 'N' THEN  'No'
	ELSE SoldAsVacant
END

-- Now if we run the SELECT DISTINCT query above we can see that all the values in the SoldAsVacant column are 'Yes' or 'No'


-- 5) Removing Duplicates. 
-- First we need to identify the duplicate rows. 

WITH RowNumCTE AS ( 
SELECT * ,
	ROW_NUMBER() over (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY 
					UniqueID
					) row_num
FROM PortofolioProject.dbo.NashvilleHousing
)
SELECT *
FROM RowNumCTE
WHERE row_num > 1

-- After executing the DELETE statement below , we can execute again the SELECT statement to check that 
-- there are no duplicates left in the table.

DELETE
FROM RowNumCTE
WHERE row_num > 1



