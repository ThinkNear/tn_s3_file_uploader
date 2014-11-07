Feature: Event log rotation

  Background: A (possibly EC2) server creates a number of logs that need to be rotated and stored on S3


  Scenario Outline: Rotated logs are updated to S3 correctly
    Given a "<input_file_pattern>" that matches "<number_files_matched_str>" files

    When the log rotation script runs for input file pattern "<input_file_pattern>" and S3 output pattern "<s3_output_pattern>"

    Then S3 contains the "<number_files_matched_str>" log files that matched "<input_file_pattern>" in the correct destination folder based on "<s3_output_pattern>"

  Examples:
    | input_file_pattern           | number_files_matched_str | s3_output_pattern                                                                                               |
    | ./target/warning.log.*.gz    | 2                        | bucket1/warnings/y=%Y/m=%m/d=%d/h=%H/ip-%{ip-address}.%{file-timestamp}.%{file-name}.%{file-extension}          |
    | ./target/error.log.*.gz      | 1                        | bucket1/errors/y=%Y/m=%m/d=%d/h=%H/ip-%{ip-address}.%{file-timestamp}.%{file-name}.%{file-extension}            |
    | ./target/fatal.log.*.gz      | 3                        | bucket1/fatals/y=%Y/m=%m/d=%d/h=%H/mm=00/ip-%{ip-address}.%{file-timestamp}.%{file-name}.%{file-extension}      |
    | ./target/info.log.*.gz       | 2                        | bucket1/infos/year=%Y/month=%m/day=%d/hour=%H/ip-%{ip-address}.%{file-timestamp}.%{file-name}.%{file-extension} |
    | ./target/startup.log.*.gz    | 1                        | bucket2/startup/y=%Y/m=%m/d=%d/h=%H/mm=00/ip-%{ip-address}.%{file-timestamp}.%{file-name}.%{file-extension}     |
    | ./target/threadump.log.*.gz  | 3                        | bucket2/threadump/y=%Y/m=%m/d=%d/h=%H/ip-%{ip-address}.%{file-timestamp}.%{file-name}.%{file-extension}         |
    | ./target/stacktrace.log.*.gz | 2                        | bucket2/stacktrace/y=%Y/m=%m/d=%d/h=%H/ip-%{ip-address}.%{file-timestamp}.%{file-name}.%{file-extension}        |