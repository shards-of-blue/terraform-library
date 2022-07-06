## Library of infrastructure deployment routines

There are components in several categories:

  - CI/CD deployment setup helpers: build.sh & setup.sh
    These shell scripts are designed to work in conjunction with pipeline configuraitions


  - folder 'tf': modular terraform code to be called from deployment roots

    - tf/modules: generic terraform code free of implicit assumptions on the calling context.
      All data needed by a module is passed in thru terraform input parameters.

    - tf/profiles: terraform code that may expect its calling context to be structured in a particular way, for instance site naming conventions, site-specific design constraints etc.

    - tf/roots: terraform code that is ready-to-run as an deployment routine to roll out a fully formed infrastructure component that only needs some amount of input parameters.

