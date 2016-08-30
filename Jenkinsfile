#!groovy

rubyGem {
    test_script = """
    #!/bin/bash -l
    rvm use .
    bundle install
    """

    build_script = 'gem build tn_s3_file_uploader.gemspec'
}
