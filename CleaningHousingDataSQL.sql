/*
Cleaning Housing Data in SQL Queries  
BY: Akshay Verma
*/

SELECT *
FROM [PortfolioProject].[dbo].[NashvilleHousing]

--------------------------------------------------------------------------------------------------------------------------

-- * Populate Property Address Data * --

--running this command shows there are null values that we need to take care of
SELECT PropertyAddress
FROM NashvilleHousing
WHERE PropertyAddress is null;

-- running this command shows everything ordered by the parcelID
-- when looking through the data you can see multiple rows that might have the same parcelID and those rows have the same address
SELECT *
FROM NashvilleHousing
ORDER BY ParcelID;

-- This command will allow us to see a side by side comparison of similar parcel IDs with their missing address by doing a self join
SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM NashvilleHousing a
JOIN NashvilleHousing b
    on a.ParcelID = b.ParcelID
    AND a.[UniqueID] <> b.[UniqueID]
WHERE a.PropertyAddress is NULL;

--This command will update the null Property adresses
UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM NashvilleHousing a
JOIN NashvilleHousing b
    on a.ParcelID = b.ParcelID
    AND a.[UniqueID] <> b.[UniqueID]
WHERE a.PropertyAddress is NULL;

--running this command again to verify no more nulls exist
SELECT PropertyAddress
FROM NashvilleHousing
WHERE PropertyAddress is null;

--------------------------------------------------------------------------------------------------------------------------

-- * Break up address into individual columns (Address, City, State) for better data analysis * --

-- Running this command shows that the delimiter in PropertyAddress is a comma
SELECT PropertyAddress
FROM NashvilleHousing;

-- This query allows us to make two seperate columns one with the address and the other with city name
SELECT 
SUBSTRING(PropertyAddress, 1, (CHARINDEX(',', PropertyAddress) -1)) as Address
, SUBSTRING(PropertyAddress, (CHARINDEX(',', PropertyAddress) + 1), LEN(PropertyAddress) ) as City
FROM NashvilleHousing;

-- Create two new columns one with address and the other with city and update them to the substrings from the previous query
ALTER TABLE NashvilleHousing
ADD PropertySplitAddress NVARCHAR(255);

UPDATE NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, (CHARINDEX(',', PropertyAddress) -1));

ALTER TABLE NashvilleHousing
ADD PropertySplitCity NVARCHAR(255);

UPDATE NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, (CHARINDEX(',', PropertyAddress) + 1), LEN(PropertyAddress) );

-- Do the same thing but in the OwnerAddressColumn, this time we will also have state column
--Instead of using substrings we can also use parseName
Select
PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3)
,PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2)
,PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1)
From PortfolioProject.dbo.NashvilleHousing;

-- Create your three new columns and update them to the values above from your ParseName statement
ALTER TABLE NashvilleHousing
Add OwnerSplitAddress Nvarchar(255);

Update NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3);

ALTER TABLE NashvilleHousing
Add OwnerSplitCity Nvarchar(255);

Update NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2);

ALTER TABLE NashvilleHousing
Add OwnerSplitState Nvarchar(255);

Update NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1);

-- validate code
Select *
From PortfolioProject.dbo.NashvilleHousing;

--------------------------------------------------------------------------------------------------------------------------

-- * Change Y and N to Yes and No in "Sold as Vacant" Column

-- If you glance over the excel file you might see that there are no Y or N values however this code
-- will show you that there are 4 different results: "Yes", "No", "Y", and "N"
SELECT DISTINCT(SoldAsVacant)
FROM NashvilleHousing;

-- Specifically we have 52 Y values and 399 N values
Select Distinct(SoldAsVacant), Count(SoldAsVacant)
From PortfolioProject.dbo.NashvilleHousing
Group by SoldAsVacant
order by 2;

-- Change the "Y's" and "N's" to "Yes" or "No" using case statements
Select SoldAsVacant
, CASE When SoldAsVacant = 'Y' THEN 'Yes'
	   When SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END
From PortfolioProject.dbo.NashvilleHousing;

-- Update your table with the code
Update NashvilleHousing
SET SoldAsVacant = CASE When SoldAsVacant = 'Y' THEN 'Yes'
	   When SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END;

-- Verify there are only 2 distinct values in that column
SELECT DISTINCT(SoldAsVacant)
FROM NashvilleHousing;

--------------------------------------------------------------------------------------------------------------------------
-- * Remove Duplicates * --

-- It's not standard practice to delete data but here we will remove the duplicates
-- This shows all duplicates whether it be ParcelID, Property Address, Sale Price, Sale Date, Legeal Reference
WITH RowNumCTE AS(
Select *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num

From PortfolioProject.dbo.NashvilleHousing
)
Select *
From RowNumCTE
Where row_num > 1
Order by PropertyAddress;

-- This will delete all of them, (AGAIN YOU SHOULD NEVER ACTUALLY JUST DELETE DATA BUT THIS IS DATA THAT IM JUST USING TO SHOWCASE THIS SKILL)
WITH RowNumCTE AS(
Select *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num

From PortfolioProject.dbo.NashvilleHousing
)
DELETE
From RowNumCTE
Where row_num > 1;

-- If you run this again you should see an empty table meaning there are no more duplicates
WITH RowNumCTE AS(
Select *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num

From PortfolioProject.dbo.NashvilleHousing
)
Select *
From RowNumCTE
Where row_num > 1
Order by PropertyAddress;

Select *
From PortfolioProject.dbo.NashvilleHousing;

--------------------------------------------------------------------------------------------------------------------------

-- * Delete Unused Columns * --

Select *
From PortfolioProject.dbo.NashvilleHousing;

-- We dont need these columns because they were either already manipulated or are not necessary
ALTER TABLE PortfolioProject.dbo.NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate;

-- Verify Columns are not there
Select *
From PortfolioProject.dbo.NashvilleHousing;


------------------------------------------------------------------------------------------------------------------------

/*
DONE
*/