# Medical-Device-Data-Sample--CDISC-Standardization
Creates a set of [SAS Transport Files](https://www.cdisc.org/kb/articles/short-history-cdisc-and-sas-transport-files). for Sample Medical Device Data in CDISC Format

Overview

This repository provides SAS scripts, templates, and resources for generating sample medical device data that conforms to CDISC (Clinical Data Interchange Standards Consortium) SDTM standards, suitable for regulatory and research submissions.

## Features

- CDISC-compliant data generation workflows for medical devices
- Modular and reusable SAS macros and programs
- Example input datasets and output
- Guidance for regulatory submission preparation

## Getting Started

1. **Clone the Repository**
   ```sh
   git clone https://github.com/<your-username>/<your-repo>.git
   ```

2. **Prepare Your SAS Environment**
   - Ensure SAS is installed and configured.
   - Place your raw data files in the `data/raw/` directory.

3. **Run the Example Program**
   - Launch SAS and execute:
     ```sas
     %include "programs/dx_07.sas";
     %include "programs/di_03.sas";
     %include "programs/do_01.sas";
     %include "programs/du_01.sas";
     ```

## Repository Structure

```
data/           # Example and raw data files
docs/           # Additional documentation
programs/       # SAS programs and macros
.github/        # GitHub configuration, issue, and PR templates
```

## License

Distributed under the [MIT License](LICENSE).

## Contact

For questions or support, open an issue or contact timothy.bullock@gmail.com
