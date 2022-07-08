## Library of infrastructure deployment routines

There are components in several categories:

  - CI/CD deployment setup helpers: build.sh & setup.sh
    These shell scripts are designed to work in conjunction with pipeline configuraitions


  - folder 'tf': modular terraform code to be called from deployment roots

    - tf/modules: generic terraform code free of implicit assumptions on the calling context.
      All data needed by a module is passed in thru terraform input parameters.

    - tf/profiles: terraform code that may expect its calling context to be structured in a particular way, for instance site naming conventions, site-specific design constraints etc.

    - tf/roots: terraform code that is ready-to-run as an deployment routine to roll out a fully formed infrastructure component that only needs some amount of input parameters.


Note that terraform module and profile names are versioned (with a '-vX' suffix). This is done to reduce the risk of terraform getting confused by too many internal layout changes. So if any major changes are made that may keep terraform from reconciling the existing state of resources that are deployed already then introduce a new version of module/profile so existing terraform deployment are not affected.
