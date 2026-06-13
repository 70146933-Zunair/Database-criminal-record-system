 # Database Criminal Record System (CRMS)

A relational database project built using PostgreSQL to manage criminal records, FIRs, cases, evidence, and police officers.

## Tools Used
- PostgreSQL
- pgAdmin 4

## Database Tables
- `police_officer` — stores officer details and badge info
- `complainant` — stores complainant personal info and statements
- `fir` — First Information Reports linked to officers and complainants
- `crm_case` — court cases linked to FIRs and investigating officers
- `criminal` — criminal profiles with status tracking
- `criminal_fir` — bridge table linking criminals to FIRs
- `evidence` — evidence items linked to cases
- `repeat_offender` — subtype for criminals with multiple offenses
- `first_time_offender` — subtype for first-time criminals

## Queries Included
1. All criminals with their FIRs and roles
2. Ongoing cases with investigating officer
3. FIR count per officer
4. Evidence for a specific case
5. Criminals linked to more than one FIR
6. FIRs filed in a date range with complainant details
7. Convicted cases with criminal details
8. Imprisoned criminals with their cases
9. Case distribution by type with percentage
10. Full criminal profile report
