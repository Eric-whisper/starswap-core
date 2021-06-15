// Copyright (c) The Starcoin Core Contributors
// SPDX-License-Identifier: Apache-2.0
// check: EXECUTED


script {

    use 0x1::Signer;

    fun init(account: signer) {
        assert(Signer::address_of(&account) == 0x1, 8000);
    }
}