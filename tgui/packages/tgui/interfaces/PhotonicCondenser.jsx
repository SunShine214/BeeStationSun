import { Section } from 'tgui/components';

import { useBackend } from '../backend';
import { Window } from '../layouts';

export const PhotonicCondenser = (props) => {
  const { act, data } = useBackend();
  return (
    <Window width={450} height={460}>
      <Window.Content scrollable>
        <Section title="hi" />
      </Window.Content>
    </Window>
  );
};
