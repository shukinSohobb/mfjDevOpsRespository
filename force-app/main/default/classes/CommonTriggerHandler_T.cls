@isTest
private class CommonTriggerHandler_T {
    private static final String TRIGGER_CONTEXT_ERROR = 'Trigger handler called outside of Trigger execution';

    private static String lastMethodCalled;

    private static CommonTriggerHandler_T.TestHandler handler;

    static {
        handler = new CommonTriggerHandler_T.TestHandler();
        // override its internal trigger detection
        handler.isTriggerExecuting = true;
    }

    /***************************************
     * unit tests
     ***************************************/

    // contexts tests

    @isTest
    static void testBeforeInsert() {
        beforeInsertMode();
        handler.run();
        System.assertEquals('beforeInsert', lastMethodCalled, 'last method should be beforeInsert');
    }

    @isTest
    static void testBeforeUpdate() {
        beforeUpdateMode();
        handler.run();
        System.assertEquals('beforeUpdate', lastMethodCalled, 'last method should be beforeUpdate');
    }

    @isTest
    static void testBeforeDelete() {
        beforeDeleteMode();
        handler.run();
        System.assertEquals('beforeDelete', lastMethodCalled, 'last method should be beforeDelete');
    }

    @isTest
    static void testAfterInsert() {
        afterInsertMode();
        handler.run();
        System.assertEquals('afterInsert', lastMethodCalled, 'last method should be afterInsert');
    }

    @isTest
    static void testAfterUpdate() {
        afterUpdateMode();
        handler.run();
        System.assertEquals('afterUpdate', lastMethodCalled, 'last method should be afterUpdate');
    }

    @isTest
    static void testAfterDelete() {
        afterDeleteMode();
        handler.run();
        System.assertEquals('afterDelete', lastMethodCalled, 'last method should be afterDelete');
    }

    @isTest
    static void testAfterUndelete() {
        afterUndeleteMode();
        handler.run();
        System.assertEquals('afterUndelete', lastMethodCalled, 'last method should be afterUndelete');
    }

    @isTest
    static void testNonTriggerContext() {
        try {
            handler.run();
            System.assert(false, 'the handler ran but should have thrown');
        } catch (CommonTriggerHandler.MyException te) {
            System.assertEquals(TRIGGER_CONTEXT_ERROR, te.getMessage(), 'the exception message should match');
        } catch (Exception e) {
            System.assert(false, 'the exception thrown was not expected: ' + e.getTypeName() + ': ' + e.getMessage());
        }
    }

    // test bypass api

    @isTest
    static void testBypassAPI() {
        afterUpdateMode();

        // test a bypass and run handler
        CommonTriggerHandler.bypass('TestHandler');
        handler.run();
        System.assertEquals(null, lastMethodCalled, 'last method should be null when bypassed');
        System.assertEquals(true, CommonTriggerHandler.isBypassed('TestHandler'), 'test handler should be bypassed');
        resetTest();

        // clear that bypass and run handler
        CommonTriggerHandler.clearBypass('TestHandler');
        handler.run();
        System.assertEquals('afterUpdate', lastMethodCalled, 'last method called should be afterUpdate');
        System.assertEquals(false, CommonTriggerHandler.isBypassed('TestHandler'), 'test handler should be bypassed');
        resetTest();

        // test a re-bypass and run handler
        CommonTriggerHandler.bypass('TestHandler');
        handler.run();
        System.assertEquals(null, lastMethodCalled, 'last method should be null when bypassed');
        System.assertEquals(true, CommonTriggerHandler.isBypassed('TestHandler'), 'test handler should be bypassed');
        resetTest();

        // clear all bypasses and run handler
        CommonTriggerHandler.clearAllBypasses();
        handler.run();
        System.assertEquals('afterUpdate', lastMethodCalled, 'last method called should be afterUpdate');
        System.assertEquals(false, CommonTriggerHandler.isBypassed('TestHandler'), 'test handler should be bypassed');
        resetTest();
    }

    // private method tests

    @isTest
    static void testGetHandlerName() {
        System.assertEquals('TestHandler', handler.getHandlerName(), 'handler name should match class name');
    }

    // test virtual methods

    @isTest
    static void testVirtualMethods() {
        CommonTriggerHandler h = new CommonTriggerHandler();
        h.beforeInsert();
        h.beforeUpdate();
        h.beforeDelete();
        h.afterInsert();
        h.afterUpdate();
        h.afterDelete();
        h.afterUndelete();
    }

    /***************************************
     * testing utilities
     ***************************************/

    private static void resetTest() {
        lastMethodCalled = null;
    }

    // modes for testing

    private static void beforeInsertMode() {
        handler.setTriggerContext('before insert', true);
    }

    private static void beforeUpdateMode() {
        handler.setTriggerContext('before update', true);
    }

    private static void beforeDeleteMode() {
        handler.setTriggerContext('before delete', true);
    }

    private static void afterInsertMode() {
        handler.setTriggerContext('after insert', true);
    }

    private static void afterUpdateMode() {
        handler.setTriggerContext('after update', true);
    }

    private static void afterDeleteMode() {
        handler.setTriggerContext('after delete', true);
    }

    private static void afterUndeleteMode() {
        handler.setTriggerContext('after undelete', true);
    }

    // test implementation of the TriggerHandler

    private class TestHandler extends CommonTriggerHandler {
        public override void beforeInsert() {
            CommonTriggerHandler_T.lastMethodCalled = 'beforeInsert';
        }

        public override void beforeUpdate() {
            CommonTriggerHandler_T.lastMethodCalled = 'beforeUpdate';
        }

        public override void beforeDelete() {
            CommonTriggerHandler_T.lastMethodCalled = 'beforeDelete';
        }

        public override void afterInsert() {
            CommonTriggerHandler_T.lastMethodCalled = 'afterInsert';
        }

        public override void afterUpdate() {
            CommonTriggerHandler_T.lastMethodCalled = 'afterUpdate';
        }

        public override void afterDelete() {
            CommonTriggerHandler_T.lastMethodCalled = 'afterDelete';
        }

        public override void afterUndelete() {
            CommonTriggerHandler_T.lastMethodCalled = 'afterUndelete';
        }
    }
}