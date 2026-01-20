# Changelog

All notable changes to this project will be documented in this file.

## [1.2] - 19 January 2026

### Added

- All apps formatted for use with Posit Connect Cloud
- Added icons to each app to help users differentiate the tools

## [1.1] - 14 March 2025

### Added

- FA the ability to download the gene data that was input by the user for genes of selected GO terms
- red outlining to the input text fields of FA
- tutorial MD GitHub links to DA, FA, and NA
- citation section and details to the information tab of each application 
- tip 6 on DA noting that HTSeq stats (no_feature, ambiguous, too_low_aQual, not_aligned, alignment_not_unique) are automatically removed from the input counts table

### Fixed

- FA ontology results output file naming

### Changed

- None

### Removed

- None

## [1.2] - 30 October 2025

### Added

- Separate set of apps for Posit Cloud and notes about the difference on the getting started pages

### Fixed

- FA ontology level (BP, MF, CC) GO term and gene ID data on the results tab
- Issue with DA app running both pairwise and GLM analysis on button press

### Changed

- Updated package install lists to only check for necessary packages
- Switched delimiter for reading GO term mappings files in the FA app

### Removed

- Removed diagrams showing the names of sets and set intersections in the SO app, since this caused issues resulting from updates to the ggVennDiagram package
- Removed un-filtered pheatmaps and report generation from the cloud DA app

## [1.3] - 17 November 2025

### Added

- Ability to input to the FA app the gene score tables from DESeq2 results
- dev folder for apps and scripts under development

### Fixed

- None

### Changed

- None

### Removed

- None