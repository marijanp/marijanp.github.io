
<h1 id="title">Kairos: Automated Integration Testing</h1>
<p>
  <address>By <a rel="author">Marijan</a></address> on <time id="post-date" datetime="2024-09-29">2024-09-29</time>
</p>

<p id="excerpt">
Learn how to build reproducible, automated system tests using NixOS and virtual machines. Ideal for CI pipelines and verifying end-to-end functionality.
</p>

<link rel="canonical" href="https://medium.com/casperblockchain/kairos-automated-integration-testing-71e2398f340d" />

> **Note:** Originally published on [Medium](https://medium.com/casperblockchain/kairos-automated-integration-testing-71e2398f340d) for Casper Association R&D

## Foundations

According to [ISTQB's](https://www.istqb.org/) [Foundations of Software Testing](https://books.google.de/books/about/Foundations_of_Software_Testing.html?id=h6h2AQAACAAJ), testing can be grouped into various levels: unit, integration, system, and acceptance testing. The primary goals of system testing are:

- To **verify** that the system performs end-to-end tasks as specified by the requirements.
- To **validate** that the delivered system meets users' needs and expectations in its operational environment.
- To **identify** defects and **prevent** them from escaping to production.

To achieve these goals, system testing should cover the end-to-end behavior of functional aspects of the system. In the case of [Kairos](https://github.com/cspr-rad/kairos), our [zero-knowledge validium](https://ethereum.org/en/developers/docs/scaling/validium/), this includes the deposit, transfer, withdrawal of funds, and querying the data availability layer.

A crucial requirement for system tests is that the test environment should closely mirror the final production environment to detect environment-related defects during testing. This means that we need to be able to create controlled test environments with consistent system configurations (including software versions) and configuration data.
Furthermore, reproducibility of the tests is imoportant to ensure consistent test outcomes and to increase the confidence in the quality of the software.
Additionally, having automated system-level tests that can run in a continuous integration (CI) pipeline also serve as regression tests, detecting changes that might break existing system functionality as early as possible.

In practice, unit and integration testing are typically performed by the development team, while system testing is often handled by specialist testers, either internal or external to the organization. This separation has advantages, as developers may have a biased view of the system, potentially overlooking specific usage scenarios or failing to uncover critical defects.
However, for small organizations or teams in the early stages of a development project, maintaining a dedicated specialist testing team is costly and could delay feedback for the developer. Rapid feedback is important to ensure that developers quickly learn whether their changes have broken critical end-to-end behavior while they still have fresh knowledge about the feature they are implementing.
To reduce feedback time, it is desirable to have automated system tests that closely replicate the production environment and can be integrated into a CI pipeline. This is why we decided to leverage NixOS tests.

[NixOS tests](https://nix.dev/tutorials/nixos/integration-testing-using-virtual-machines.html#introduction) offer a powerful solution for achieving automated, controlled, reproducible test environments. [NixOS](https://nixos.org/) is a Linux distribution that allows us to define an entire system's configuration, from the operating system to specific application versions and dependencies in a declarative manner. One or more NixOS configurations can then be passed to a NixOS test function, which will create one or more virtual machines (VMs), where each VM is deployed with the respective NixOS configuration activated. The test function allows us to define interactions between multiple VMs programatically using Python, allowing us to simulate complex scenarios involving network communication, query and assert system states, and more.
In the event of a failing test, we can start an interactive test session that allows us to log into the defined virtual machines. This enables us to use tools like `journalctl` and other applications for debugging. Towards the end of this blog post, we will demonstrate how to initiate such an interactive test session.
To get a better idea how such a NixOS test looks like, let's take a look at the end-to-end test we defined for Kairos and go through the relevant snippets.

---

## NixOS Test Walkthrough

As mentioned previously, the `nixosTest` function allows us to declare one or more NixOS configurations, which will be instantiated and started as VMs in our test. In this case, we define both a server and a client node. For the server node, we leverage Nix and use our predefined function called `mkKairosHostConfig`, which produces a deployable production configuration for our Kairos application. This function takes a single parameter to set the hostname to "kairos", allowing us to refer to the server as `kairos` later in the test script. We then make some test-specific modifications to that production configuration to adjust it for testing:

- We disable HTTPS for convenience, to avoid issuing SSL certificates in the test environment.
- We add and enable the cctl NixOS module, which starts a one-shot systemd service that initiates a new network of Casper nodes and deploys the defined smart contract once the genesis has passed.
- We configure Kairos to connect to one of the nodes spun up by cctl, and we modify the systemd service to start after the cctl service and to use the contract hash that we receive after the smart contract is deployed. This step is fortunately only required for testing; in production, we would simply set the contract hash to the appropriate value once the deployment is complete.

On the client node, we install the `kairos-cli` and `wget`, which is required to download the test wallets generated by `cctl`.

```nix
nixosTest {
...
  nodes = {
    server = { config, lib, ... }: {
      imports = [
        (mkKairosHostConfig "kairos")
        cctlModule
      ];

      virtualisation.cores = 4;
      virtualisation.memorySize = 4096;

      # allow HTTP for nixos-test environment
      services.nginx.virtualHosts.${config.networking.hostName} = {
        forceSSL = lib.mkForce false;
        enableACME = lib.mkForce false;
      };

      # Required to await successful contract deployment
      environment.systemPackages = [ casper-client-rs ];

      services.cctl = {
        enable = true;
        contract = { "kairos_contract_package_hash" = kairos-contracts + "/bin/demo-contract-optimized.wasm"; };
        chainspec = casper-chainspec;
        config = casper-node-config;
      };

      services.kairos = {
        casperRpcUrl = "http://localhost:${builtins.toString config.services.cctl.port}/rpc";
        casperSseUrl = "http://localhost:18101/events/main"; # has to be hardcoded since cctl is not configurable
        # This is a mandatory module option, we set it to 0. This will be overwritten, see systemd.services.kairos.serviceConfig.ExecStart.
        demoContractHash = "0000000000000000000000000000000000000000000000000000000000000000";
        casperSyncInterval = 2;
      };
      systemd.services.kairos = {
        # We have to wait for cctl to deploy the contract to be able to obtain and export the contract hash
        after = [ "network-online.target" "cctl.service" ];
        requires = [ "network-online.target" "cctl.service" ];
        serviceConfig.ExecStart = lib.mkForce (writeShellScript "start-kairos" ''
          # cctl will write the deployed contract hash to a file whose name is configured by services.cctl.contracts
          export KAIROS_SERVER_DEMO_CONTRACT_HASH=$(cat "${config.services.cctl.workingDirectory}/contracts/kairos_contract_package_hash")
          ${lib.getExe kairos}
        '');
      };
    };
    client = { pkgs, ... }: {
      environment.systemPackages = [ pkgs.wget kairos ];
    };
...
}
```

Now that we have defined the participants in the test, we need to define the test script that will be executed. The script is written in Python, a language that is widely accessible and understood by almost anyone, and provides many useful packages that we can leverage in our tests, such as `json` and `backoff`.

We define three utility functions that will be used later in the script: one to wait for a deployment to be successfully completed on the L1 (i.e., the Casper network), and another to wait for a transaction to be submitted to the L2 (i.e., Kairos).

The test script begins with some synchronization instructions. The NixOS test driver makes the previously defined nodes available as variables that we can use to perform synchronization or execute commands on the command line. The list of available methods can be found here. We wait for the server's systemd services - cctl, kairos, and nginx-to start. For the client, we simply wait for the multi-user target to be reached.

Next, we copy the cctl-generated test wallets to the client machine so that we can use the respective secret keys when invoking the kairos-cli.

Now, the actual test definition begins. We test deposit, transfer, withdraw, and we query the data availability layer, simulating how a user would interact with the system in the real world, on a completely separate machine over a network (NixOS tests run in an isolated environment with a virtual network).

```nix
...
extraPythonPackages = p: [ p.backoff ];
testScript = { nodes }:
  let
    casperNodeAddress = "http://localhost:${builtins.toString nodes.server.config.services.cctl.port}";
    # This is the directory wget will copy to, see script below
    clientUsersDirectory = "kairos/cctl/users";
  in
  ''
    import json
    import backoff

    # Utils
    def verify_deploy_success(json_data):
      # Check if the "Success" key is present
      try:
        if "result" in json_data and "execution_results" in json_data["result"]:
          for execution_result in json_data["result"]["execution_results"]:
            if "result" in execution_result and "Success" in execution_result["result"]:
              return True
      except KeyError:
        pass
      return False

    @backoff.on_exception(backoff.expo, Exception, max_tries=5, jitter=backoff.full_jitter)
    def wait_for_successful_deploy(deploy_hash):
      client_output = kairos.succeed("casper-client get-deploy --node-address ${casperNodeAddress} {}".format(deploy_hash))
      get_deploy_result = json.loads(client_output)
      if not verify_deploy_success(get_deploy_result):
        raise Exception("Success key not found in JSON")

    @backoff.on_exception(backoff.expo, Exception, max_tries=5, jitter=backoff.full_jitter)
    def wait_for_transaction(sender, transaction_type, amount):
      transactions_result = client.succeed("kairos-cli --kairos-server-address http://kairos fetch --sender {} --transaction-type {}".format(sender, transaction_type))
      transactions = json.loads(transactions_result)
      if not any(transaction.get("public_key") == sender and transaction.get("amount") == str(amount) for transaction in transactions):
        raise Exception("Couldn't find {} for sender {} with amount {} in transactions\n:{}".format(transaction_type, sender, amount, transactions))

    # Test
    start_all()

    kairos.wait_for_unit("cctl.service")
    kairos.wait_for_unit("kairos.service")
    kairos.wait_for_unit("nginx.service")
    kairos.wait_for_open_port(80)

    client.wait_for_unit ("multi-user.target")

    # We need to copy the cctl generated assets from the server to the client machine,
    # because the invocations of the kairos-cli on the client make use of them.
    # The cctl module enables serving of those generated assets on the server,
    client.succeed("wget --no-parent -r http://kairos/cctl/users/")

    # CLI with ed25519
    # deposit
    deposit_amount = 3000000000
    depositor = client.succeed("cat ${clientUsersDirectory}/user-2/public_key_hex")
    depositor_private_key = "${clientUsersDirectory}/user-2/secret_key.pem"
    deposit_deploy_hash = client.succeed("kairos-cli --kairos-server-address http://kairos deposit --amount {} --recipient {} --private-key {}".format(deposit_amount, depositor, depositor_private_key))
    assert int(deposit_deploy_hash, 16), "The deposit command did not output a hex encoded deploy hash. The output was {}".format(deposit_deploy_hash)

    wait_for_successful_deploy(deposit_deploy_hash)

    wait_for_transaction(depositor, "deposit", deposit_amount)

    # transfer
    transfer_amount = 1000
    beneficiary = client.succeed("cat ${clientUsersDirectory}/user-3/public_key_hex")
    transfer_output = client.succeed("kairos-cli --kairos-server-address http://kairos transfer --amount {} --recipient {} --private-key {}".format(transfer_amount, beneficiary, depositor_private_key))
    assert "Transfer successfully sent to L2\n" in transfer_output, "The transfer command was not successful: {}".format(transfer_output)

    # data availability
    transactions_result = client.succeed("kairos-cli --kairos-server-address http://kairos fetch --recipient {}".format(beneficiary))
    transactions = json.loads(transactions_result)
    assert any(transaction.get("recipient") == beneficiary and transaction.get("amount") == str(transfer_amount) for transaction in transactions), "Couldn't find the transfer in the L2's DA: {}".format(transactions)

    # withdraw
    withdrawal_amount = 800
    withdrawer = client.succeed("cat ${clientUsersDirectory}/user-3/public_key_hex")
    withdrawer_private_key = "${clientUsersDirectory}/user-3/secret_key.pem"
    withdraw_output = client.succeed("kairos-cli --kairos-server-address http://kairos withdraw --amount {} --private-key {}".format(withdrawal_amount, withdrawer_private_key))
    assert "Withdrawal successfully sent to L2\n" in withdraw_output, "The withdraw command was not successful: {}".format(withdraw_output)

    wait_for_transaction(withdrawer, "withdrawal", withdrawal_amount)
  '';
...
```

The complete test definition in package-normal-form can be found here: [https://github.com/cspr-rad/kairos/blob/0.1.0/nixos/tests/end-to-end.nix](https://github.com/cspr-rad/kairos/blob/0.1.0/nixos/tests/end-to-end.nix)

To run our Kairos end-to-end test you can execute the following command after installing Nix:
```console
$ nix build github:cspr-rad/kairos#kairos#checks.x86_64-linux.kairos-end-to-end-test -L
```

An interactive session that allows you to log into the server and client can be started by running:

```console
$ nix build github:cspr-rad/kairos#kairos#checks.x86_64-linux.kairos-end-to-end-test.driverInteractive
```

The interactive test driver will be symlinked to `result/bin/nixos-test-driver`. You can execute this binary, and once you are dropped into an Emacs session, you can run `start_all()` to start all the nodes. You can then log into the machines as root with an empty password. For more sophisticated usage, please refer to the blog posts linked at the end of this post and the NixOS manual.

---

This is by no means everything that NixOS tests can do. In the `nixpkgs` package set, you can find tests for multiplayer games, BitTorrent, desktop environments, and more. To learn more about NixOS tests, I recommend reading the following resources:

- [https://nixcademy.com/posts/nixos-integration-tests/](https://nixcademy.com/posts/nixos-integration-tests/)
- [https://nixcademy.com/posts/nixos-integration-tests-part-2/](https://nixcademy.com/posts/nixos-integration-tests/)
- [https://nix.dev/tutorials/nixos/integration-testing-using-virtual-machines.html](https://nix.dev/tutorials/nixos/integration-testing-using-virtual-machines.html)

To run NixOS tests on MacOS, please refer to:

- [https://nixcademy.com/posts/running-nixos-integration-tests-on-macos/](https://nixcademy.com/posts/running-nixos-integration-tests-on-macos/)
